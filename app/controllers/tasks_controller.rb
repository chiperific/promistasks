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
  end

  def create
    authorize @task = Task.find(params[:id])
    # redirect_to @return_path, notice: 'Task created'
  end

  def edit
    authorize @task = Task.find(params[:id])
  end

  def update
    authorize @task = Task.find(params[:id])
    # redirect_to @return_path, notice: 'Task updated'
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
end
