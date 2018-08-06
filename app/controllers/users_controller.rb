# frozen_string_literal: true

class UsersController < ApplicationController
  include UsersHelper
  # https://github.com/plataformatec/devise/wiki/How-To:-Manage-users-through-a-CRUD-interface

  def index
    authorize users = User.all.order(:name)
    @show_new = users.created_since(current_user.last_sign_in_at).count.positive?

    case params[:filter]
    when 'new'
      @users = users.created_since(current_user.last_sign_in_at)
      @empty_msg = 'No people created since you last signed in'
    when 'staff'
      @users = users.staff
      @empty_msg = 'No staff'
    when 'clients'
      @users = users.clients
      @empty_msg = 'No clients'
    when 'volunteers'
      @users = users.volunteers
      @empty_msg = 'No volunteers'
    when 'contractors'
      @users = users.contractors
      @empty_msg = 'No contractors'
    when 'admins'
      @users = users.system_admins
      @empty_msg = 'No System Admins'
    when 'archived'
      @users = users.discarded
      @empty_msg = 'No archived people'
    else # 'all' || nil
      @users = users.undiscarded
      @empty_msg = 'No people found'
    end

    respond_to do |format|
      format.js
      format.html
    end
  end

  def show
    authorize @user = User.find(params[:id])

    @tasks = Task.related_to(@user)
    @properties = Property.related_to(@user)

    @default_property = Property.where(is_default: true, creator: @user).first

    @primary_info_hash = {
      'Name': @user.name,
      'Email': @user.email,
      'Title': @user.title.blank? ? '-' : @user.title,
      'Type': @user.readable_type,
      'Phone 1': @user.phone1.blank? ? '-' : @user.phone1,
      'Phone 2': @user.phone2.blank? ? '-' : @user.phone2,
      'Address': @user.first_address.blank? ? '-' : @user.first_address,
      'Location': @user.location_address.blank? ? '-' : @user.location_address
    }

    @skills = @user.skills.order(:name)
    @tasks_finder_count = Task.visible_to(@user).joins(:skills).where(skills: { id: @skills.pluck(:id) }).uniq.count
    @connections = @user.connections.except_tennants
    @occupancies = @user.connections.only_tennants
  end

  def tasks
    authorize @user = User.find(params[:id])
    tasks = Task.related_to(@user)
    @show_new = tasks.created_since(current_user.last_sign_in_at).count.positive?

    case params[:filter]
    when 'new'
      @tasks = tasks.in_process.created_since(current_user.last_sign_in_at)
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
    when 'all'
      @tasks = tasks
      @empty_msg = 'No active tasks'
    when 'archived'
      @tasks = tasks.archived
      @empty_msg = 'No archived tasks'
    else # nil || 'active'
      @tasks = tasks.in_process
      @empty_msg = 'No active tasks'
    end

    respond_to do |format|
      format.js
      format.html
    end
  end

  def tasks_finder
    authorize @user = User.find(params[:id])

    skill_ids = @user.skills.pluck(:id)
    @tasks = Task.visible_to(@user).joins(:skills).where(skills: { id: skill_ids }).uniq
  end

  def skills
    authorize @user = User.find(params[:id])
    @skills = Skill.active.order(:name)
  end

  def update_skills
    authorize @user = User.find(params[:id])

    current = @user.skills.map(&:id)

    if user_skills_params[:add_skills].present?
      add = JSON.parse(user_skills_params[:add_skills]).map(&:to_i)
      existing = current & add
      add -= existing
      @user.skills << Skill.find(add)
    end

    if user_skills_params[:remove_skills].present?
      remove = JSON.parse(user_skills_params[:remove_skills]).map(&:to_i)
      remove = current & remove
      @user.skills.delete(Skill.find(remove))
    end

    redirect_to @return_path
    if add.nil? && remove.nil?
      flash[:alert] = 'Nothing changed'
    else
      flash[:alert] = 'Skills updated!'
    end
  end

  def new
    authorize @user = User.new
    @hide_rate = 'scale-out'
  end

  def create
    authorize @user = User.new(user_params)

    if @user.save
      redirect_to @return_path, notice: 'User created'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'new'
    end
  end

  def edit
    authorize @user = User.find(params[:id])
    @hide_rate = 'scale-out' unless @user.contractor?
  end

  def update
    authorize @user = User.find(params[:id])
    @user.discard if params[:user][:archive] == '1' && !@user.discarded?
    @user.undiscard if params[:user][:archive] == '0' && @user.discarded?

    # .reject removes password and password_confirmation if they are blank
    if @user.update(user_params.reject { |k, v| k.include?('password') && v.blank? })
      redirect_to @return_path, notice: 'Update successful'
    else
      flash[:warning] = 'Oops, found some errors'
      @hide_rate = 'scale-out' unless @user.contractor? || user_params[:contractor] != '0'
      render 'edit'
    end
  end

  def oauth_check
    authorize @user = User.find(params[:id])

    @show_error_view = params[:err] == 'true'

    @primary_info_hash = {
      'Google ID?': @user.oauth_id.present? ? 'OK' : 'MISSING',
      'Google Token?': @user.oauth_token.present? ? 'OK' : 'MISSING',
      'Google Refresh Token?': @user.oauth_refresh_token.present? ? 'OK' : 'MISSING',
      'Google Token Expires at:': human_datetime(@user.oauth_expires_at.localtime)
    }
  end

  def api_sync
    authorize @user = User.find(params[:id])
    Delayed::Job.enqueue SyncUserWithApiJob.new(@user.id)
    redirect_to url_for_sync
  end

  def clear_completed_jobs
    authorize User.first
    Delayed::Job.where.not(completed_at: nil).delete_all

    if params[:cred_err] == 'true'
      redirect_to oauth_check_user_path(current_user, err: true)
    else
      redirect_to @return_path
    end
  end

  def alerts
    authorize user = User.find(params[:id])
    tasks = Task.in_process.related_to(user)
    properties = Property.related_to(user)

    @notification_json = {
      show_alert: show_alert(tasks, properties, user),
      pulse_alert: pulse_alert(tasks, properties),
      alert_color: alert_color(tasks, properties),
      tasks_past_due: {
        count: tasks.past_due.count,
        msg: tasks.past_due.count.to_s + ' past due task'.pluralize(tasks.past_due.count)
      },
      properties_over_budget: {
        count: properties.over_budget.length,
        msg: properties.over_budget.length.to_s + ' property'.pluralize(properties.over_budget.length) + ' over budget'
      },
      properties_nearing_budget: {
        count: properties.nearing_budget.length,
        msg: properties.nearing_budget.length.to_s + ' property'.pluralize(properties.nearing_budget.length) + ' nearing budget'
      },
      tasks_due_7: {
        count: tasks.due_within(7).count,
        msg: tasks.due_within(7).count.to_s + ' task'.pluralize(tasks.due_within(7).count) + ' due in next 7 days'
      },
      tasks_missing_info: {
        count: tasks.needs_more_info.count,
        msg: tasks.needs_more_info.count.to_s + ' task'.pluralize(tasks.needs_more_info.count) + ' missing info'
      },
      tasks_due_14: {
        count: tasks.due_within(14).count,
        msg: tasks.due_within(14).count.to_s + ' task'.pluralize(tasks.due_within(14).count) + ' due in next 14 days'
      },
      tasks_new: {
        count: tasks.created_since(user.last_sign_in_at).count,
        msg: tasks.created_since(user.last_sign_in_at).count.to_s + ' newly created task'.pluralize(tasks.created_since(user.last_sign_in_at).count)
      }
    }

    render json: @notification_json.as_json
  end

  def owner_enum
    authorize current_user
    user_list = User.not_clients.pluck(:name, :oauth_image_link).to_h

    render json: user_list
  end

  def subject_enum
    authorize current_user
    user_list = User.pluck(:name, :oauth_image_link).to_h

    render json: user_list
  end

  def find_id_by_name
    authorize current_user
    users = User.where(name: params[:name])

    user_id = users.present? ? users.first.id : 0

    render json: user_id
  end

  private

  def user_params
    params.require(:user).permit(:name, :title,
                                 :program_staff, :project_staff, :admin_staff,
                                 :client, :volunteer, :contractor,
                                 :rate, :rate_cents, :rate_currency,
                                 :phone1, :phone2, :address1, :address2, :city, :state, :postal_code,
                                 :email, :password, :password_confirmation,
                                 :system_admin)
  end

  def user_skills_params
    params.require(:user).permit(:add_skills, :remove_skills)
  end
end
