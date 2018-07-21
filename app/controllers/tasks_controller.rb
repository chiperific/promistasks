# frozen_string_literal: true

class TasksController < ApplicationController
  def index
    authorize tasks = Task.except_primary

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
      @tasks = tasks.archived
      @empty_msg = 'No archived tasks'
    when 'all'
      @tasks = tasks
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

  def admin
    authorize @tasks = Task.in_process
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

    @secondary_info_hash = {
      'Budget': @task.budget&.format || 'Not set',
      'Cost': @task.cost&.format || 'Not set',
      'Created on': human_date(@task.created_at),
      'Last updated': human_date(@task.updated_at),
      'Source': @task.created_from_api? ? 'Google Tasks' : 'PromiseTasks'
    }

    @secondary_info_hash['Archived on'] = human_date(@task.discarded_at) if @task.archived?
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
  end

  def create
    task_params.delete :budget if task_params[:budget].blank?
    task_params.delete :cost if task_params[:cost].blank?

    authorize @task = Task.new(parse_completed_at(task_params))

    if @task.save
      redirect_to @return_path, notice: 'Task created'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  def edit
    authorize @task = Task.find(params[:id])
  end

  def update
    authorize @task = Task.find(params[:id])

    @task.discard if params[:task][:archive] == '1' && !@task.discarded?
    @task.undiscard if params[:task][:archive] == '0' && @task.discarded?

    task_params.delete :budget if task_params[:budget].blank?
    task_params.delete :cost if task_params[:cost].blank?

    if @task.update(parse_completed_at(task_params)
      redirect_to @return_path, notice: 'Task updated'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  def destroy
    authorize @task = Task.find(params[:id])
    @task.discard
    redirect_to @return_path, notice: 'Task discarded'
  end

  def discarded
    authorize @tasks = Task.discarded
  end

  def public
    authorize @tasks = Task.public_visible
  end

  def users_finder
    authorize @task = Task.find(params[:id])
  end

  def complete
    authorize @task = Task.find(params[:id])
    @task.update(completed_at: Time.now)
    status = @task.reload.completed_at.nil? ? 'inProcess' : 'completed'
    render json: { id: @task.id.to_s, status: status }
  end

  def un_complete
    authorize @task = Task.find(params[:id])
    @task.update(completed_at: nil)
    status = @task.reload.completed_at.nil? ? 'inProcess' : 'completed'
    render json: { id: @task.id.to_s, status: status }
  end

  private

  def task_params
    params.require(:task).permit(:title, :notes, :priority, :due, :visibility, :completed_at,
                                 :creator_id, :owner_id, :subject_id, :property_id,
                                 :budget, :cost)
  end

  def task_skills_params
    params.require(:task).permit(:add_skills, :remove_skills)
  end
end
