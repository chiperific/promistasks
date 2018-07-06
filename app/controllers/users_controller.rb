# frozen_string_literal: true

class UsersController < ApplicationController
  include UsersHelper
  # https://github.com/plataformatec/devise/wiki/How-To:-Manage-users-through-a-CRUD-interface

  def index
    authorize @users = User.undiscarded
  end

  def show
    authorize @user = User.find(params[:id])
    redirect_to users_path
  end

  def new
    authorize @user = User.new
    @hide_rate = 'scale-out'
  end

  def create
    modified_params = user_params.except :archive
    authorize @user = User.new(modified_params)

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
    @user.discard if user_params[:archive] == '1'
    modified_params = user_params.except :archive
    if params[:password].nil?
      modified_params = user_params.except :password, :password_confirmation, :archive
    end

    if @user.update(modified_params)
      redirect_to @return_path, notice: 'Update successful'
    else
      flash[:warning] = 'Oops, found some errors'
      render 'edit'
    end
  end

  def destroy
    authorize @user = User.find(params[:id])
    @user.discard
    redirect_to @return_path, notice: 'User discarded'
  end

  def discarded
    authorize @users = User.discarded
  end

  def current_user_id
    id = current_user&.id || 0
    @id = { id: id }
    render json: @id.as_json
  end

  def api_sync
    authorize @user = User.find(params[:id])
    Delayed::Job.enqueue SyncUserWithApiJob.new(@user.id)
    redirect_to url_for_sync
  end

  def clear_completed_jobs
    authorize User.first
    Delayed::Job.where.not(completed_at: nil).delete_all
    redirect_back fallback_location: properties_path
  end

  def alerts
    user = User.find(params[:id])
    tasks = Task.related_to(user)
    properties = Property.related_to(user)

    @notification_json = {
      show_alert: show_alert(tasks, properties, user),
      pulse_alert: pulse_alert(tasks, properties),
      alert_color: alert_color(tasks, properties),
      tasks_past_due: {
        count: tasks.past_due.count,
        msg: tasks.past_due.count.to_s + ' past dues task'.pluralize(tasks.past_due.count)
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

  private

  def user_params
    params.require(:user).permit(:name, :title,
                                 :program_staff, :project_staff, :admin_staff,
                                 :client, :volunteer, :contractor,
                                 :rate, :rate_cents, :rate_currency,
                                 :phone1, :phone2, :address1, :address2, :city, :state, :postal_code,
                                 :email, :password, :password_confirmation,
                                 :system_admin, :archive)
  end
end
