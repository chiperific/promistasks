# frozen_string_literal: true

class TasksController < ApplicationController
  def index
    authorize @tasks = Task.visible_to(current_user)
  end

  def show
    authorize @task = Task.find(params[:id])
  end

  def new
    authorize @task = Task.new
    @task.property_id = params[:property] if params[:property].present?
  end

  def create
    modified_params = task_params.except :archive

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

    modified_params = task_params.except :archive
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

  private

  def task_params
    params.require(:task).permit(:title, :notes, :priority, :due, :visibility, :completed_at,
                                 :creator_id, :owner_id, :subject_id, :property_id,
                                 :budget, :cost, :archive)
  end
end
