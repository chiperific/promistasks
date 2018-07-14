# frozen_string_literal: true

class TasksController < ApplicationController
  def index
    authorize tasks = Task.related_to(current_user)

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
    when 'all'
      @tasks = tasks.active
      @empty_msg = 'No active tasks'
    when 'archived'
      @tasks = tasks.archived
      @empty_msg = 'No archived tasks'
    when 'missing-info'
      @tasks = tasks.needs_more_info
      @empty_msg = 'No tasks missing info!'
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
      'Priority': @task.priority || 'Not set',
      'Due': human_date(@task.due) || 'Not set',
      'Visibile to': Constant::Task::VISIBILITY[@task.visibility],
      'Status': @task.status.capitalize
    }

    @secondary_info_hash = {
      'Budget': @task.budget&.format || 'Not set',
      'Cost': @task.cost&.format || 'Not set',
      'Created on': human_date(@task.created_at),
      'Last updated': human_date(@task.updated_at),
      'Source': @task.created_from_api? ? 'Google Tasks' : 'PromiseTasks'
    }

    @secondary_info_hash['Archived on'] = human_date(@task.discarded_at) if @task.archived?
  end

  def new
    authorize @task = Task.new
    @task.property_id = params[:property] if params[:property].present?
  end

  def create
    modified_params = parse_datetimes(task_params.except(:archive))

    modified_params.delete :budget if task_params[:budget].blank?
    modified_params.delete :cost if task_params[:cost].blank?

    authorize @task = Task.new(modified_params)

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

    @task.discard if task_params[:archive] == '1'

    modified_params = parse_datetimes(task_params.except(:archive))
    badbad
    if @task.update(modified_params)
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

  # def filter
    # authorize tasks = Task.related_to(current_user)

    # case params[:filter]
    # when 'past-due'
    #   @tasks = tasks.past_due
    #   @empty_msg = 'No tasks are over-due!'
    # when 'due-7'
    # when 'due-14'
    # when 'completed'
    #   @tasks = tasks.complete
    #   @empty_msg = 'No completed tasks'
    # when 'all'
    #   @tasks = tasks.active
    #   @empty_msg = 'No active tasks'
    # when 'archived'
    #   @tasks = tasks.archived
    #   @empty_msg = 'No archived tasks'
    # when 'missing-info'
    #   @tasks = tasks.needs_more_info
    #   @empty_msg = 'No tasks missing info!'
    # else # nil || 'active'
    #   @tasks = tasks.in_process
    #   @empty_msg = 'No active tasks'
    # end

    # respond_to do |format|
    #   format.js
    # end
  # end

  private

  def task_params
    params.require(:task).permit(:title, :notes, :priority, :due, :visibility, :completed_at,
                                 :creator_id, :owner_id, :subject_id, :property_id,
                                 :budget, :cost, :archive)
  end
end
