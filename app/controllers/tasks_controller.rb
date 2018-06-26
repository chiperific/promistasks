# frozen_string_literal: true

class TasksController < ApplicationController
  def index
    @tasks = Task.visible_to(current_user)
  end

  def show
    @task = Task.find(params[:id])
  end

  def new
    @task = Task.new
  end

  def create
    @task = Task.find(params[:id])
  end

  def edit
    @task = Task.find(params[:id])
  end

  def update
    @task = Task.find(params[:id])
  end

  def destroy
    @task = Task.find(params[:id])
    @task.discard
    redirect_to tasks_url, notice: 'Task discarded'
  end

  def discarded
    @tasks = Task.discarded
  end

  def public
    if current_user
      @tasks = Task.visible_to(current_user)
    else
      @tasks = Task.public_visible
    end
  end
end
