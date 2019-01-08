# frozen_string_literal: true

class TasksController < ApplicationController
  include TasksHelper

  def index
    authorize Task
    tasks = Task.except_primary.visible_to(current_user)

    @show_new = tasks.created_since(current_user.last_sign_in_at).count.positive?

    case params[:filter]
    when 'new'
      @tasks = tasks.created_since(current_user.last_sign_in_at)
      @empty_msg = 'No tasks created since you last signed in'
    when 'past-due'
      @tasks = tasks.past_due
      @empty_msg = 'No tasks are over-due!'
    when 'due-7'
      @tasks = tasks.due_within(7)
      @empty_msg = 'No tasks due in next 7 days!'
    when 'due-14'
      @tasks = tasks.due_within(14)
      @empty_msg = 'No tasks due in next 14 days!'
    when 'completed'
      @tasks = tasks.complete
      @empty_msg = 'No completed tasks'
    when 'missing-info'
      @tasks = tasks.needs_more_info
      @empty_msg = 'No tasks missing info!'
    when 'archived'
      @tasks = Task.except_primary.archived
      @empty_msg = 'No archived tasks'
    when 'all'
      @tasks = Task.except_primary
      @empty_msg = 'No active tasks'
    else # nil || 'active'
      @tasks = tasks.in_process
      @empty_msg = 'No active tasks'
    end

    respond_to do |format|
      format.js
      format.html
    end
  end

  def public_index
    authorize @tasks = Task.in_process.public_visible
    @organization = Organization.first

    if @organization.volunteer_contact.present?
      contact = @organization.volunteer_contact
      @org_contact_name = contact.fname
      @org_contact_email = contact.email
      @org_contact_phone = contact.phone
    else
      @org_contact_name = 'We'
      @org_contact_email = @organization.default_email
      @org_contact_phone = @organization.default_phone
    end
  end

  def show
    authorize @task = Task.find(params[:id])

    @primary_info_hash = {
      'Priority': @task.priority.present? ? Constant::Task::PRIORITY[@task.priority] : 'Not set',
      'Due': human_date(@task.due) || 'Not set',
      'Visibile to': Constant::Task::VISIBILITY[@task.visibility],
      'Status': @task.status.capitalize
    }

    @skills = @task.skills
    @user_finder_count = User.undiscarded.joins(:skills).where(skills: { id: @skills.pluck(:id) }).uniq.count

    @secondary_info_hash = {
      'Budget': @task.budget&.format || 'Not set',
      'Cost': @task.cost&.format || 'Not set',
      'Created on': human_date(@task.created_at),
      'Last updated': human_date(@task.updated_at),
      'Source': @task.created_from_api? ? 'Google Tasks' : 'PromiseTasks'
    }

    @payments = @task.payments

    if @task.visibility = 1
      @vol_info_hash = {
        'Group opportunity': human_boolean(@task.volunteer_group),
        'Professionals only': human_boolean(@task.professional),
        'Volunteers Needed': @task.min_volunteers.to_s + ' - ' + @task.max_volunteers.to_s,
        'Estimated Hours': @task.estimated_hours,
        'Actual Volunteers': @task.actual_volunteers,
        'Actual Hours': @task.actual_hours
      }
    end

    @secondary_info_hash['Archived on'] = human_date(@task.discarded_at) if @task.archived?
  end

  def public
    authorize @task = Task.find(params[:id])

    @organization = Organization.first

    if @organization.maintenance_contact.present?
      @task_contact = @organization.maintenance_contact.fname
      @task_email = @organization.maintenance_contact.email
      @task_phone = @organization.maintenance_contact.phone
    else
      @task_contact = @organization.name
      @task_email = @organization.default_email
      @task_phone = @organization.default_phone
    end

    if @organization.volunteer_contact.present?
      contact = @organization.volunteer_contact
      @org_contact_name = contact.fname
      @org_contact_email = contact.email
      @org_contact_phone = contact.phone
    else
      @org_contact_name = 'We'
      @org_contact_email = @organization.default_email
      @org_contact_phone = @organization.default_phone
    end
  end

  def users_finder
    authorize @task = Task.find(params[:id])
    skill_ids = @task.skills.pluck(:id)
    @users = User.undiscarded.joins(:skills).where(skills: { id: skill_ids }).uniq
  end

  def skills
    authorize @task = Task.find(params[:id])

    @skills = Skill.active.order(:name)
  end

  def update_skills
    authorize @task = Task.find(params[:id])

    current = @task.skills.map(&:id)

    if task_skills_params[:add_skills].present?
      add = JSON.parse(task_skills_params[:add_skills]).map(&:to_i)
      existing = current & add
      add -= existing
      @task.skills << Skill.find(add)
    end

    if task_skills_params[:remove_skills].present?
      remove = JSON.parse(task_skills_params[:remove_skills]).map(&:to_i)
      remove = current & remove
      @task.skills.delete(Skill.find(remove))
    end

    redirect_to @return_path
    if add.nil? && remove.nil?
      flash[:alert] = 'Nothing changed'
    else
      flash[:alert] = 'Skills updated!'
    end
  end

  def new
    authorize @task = Task.new

    @task.property_id = params[:property] if params[:property].present?
    @task.owner_id = params[:user].present? ? params[:user] : current_user.id
    @task.creator = current_user
  end

  def create
    authorize @task = Task.new(parse_completed_at(task_params.reject { |k, v| (k.include?('budget') || k.include?('cost')) && v.blank? }))

    @task.creator_id = current_user.id

    if @task.save
      redirect_to @return_path, notice: 'Task created'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  def edit
    authorize @task = Task.find(params[:id])
    @owner_lkup = @task.owner.name
  end

  def update
    authorize @task = Task.find(params[:id])

    if params[:task][:archive] == '1' && !@task.discarded?
      # remove it from Google Tasks for just this user by destroying the associated TaskUsers:
      @task.task_users.where(user: current_user).destroy_all if current_user.oauth?
      @task.discard
    end

    if params[:task][:archive] == '0' && @task.discarded?
      # add it to Google Tasks for just this user:
      @task.ensure_task_user_exists_for(current_user) if current_user.oauth?
      @task.undiscard
    end

    if @task.update(parse_completed_at(task_params.reject { |k, v| (k.include?('budget') || k.include?('cost')) && v.blank? }))
      redirect_to @return_path, notice: 'Task updated'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  def complete
    authorize @task = Task.find(params[:id])
    @task.update(completed_at: Time.now)
    status = @task.reload.completed_at.blank? ? 'inProcess' : 'completed'
    render json: { id: @task.id.to_s, status: status }
  end

  def un_complete
    authorize @task = Task.find(params[:id])
    @task.update(completed_at: nil)
    status = @task.reload.completed_at.blank? ? 'inProcess' : 'completed'
    render json: { id: @task.id.to_s, status: status }
  end

  def task_enum
    authorize tasks = Task.kept.select(:title)

    hsh = {}
    tasks.each do |task|
      hsh[task.title] = nil
    end

    render json: hsh
  end

  def find_id_by_title
    authorize current_user
    tasks = Task.where(title: params[:title])

    task_id = tasks.present? ? tasks.first.id : 0

    render json: task_id
  end

  private

  def task_params
    params.require(:task).permit(:title, :notes, :priority, :due, :visibility, :completed_at,
                                 :creator_id, :owner_id, :subject_id, :property_id,
                                 :volunteer_group, :professional, :min_volunteers, :max_volunteers,
                                 :actual_volunteers, :estimated_hours, :actual_hours,
                                 :budget, :cost)
  end

  def task_skills_params
    params.require(:task).permit(:add_skills, :remove_skills)
  end
end
