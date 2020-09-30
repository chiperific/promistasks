# frozen_string_literal: true

class AutoTasksController < ApplicationController
  protect_from_forgery except: :edit

  before_action :set_auto_task, only: %i[edit update destroy]

  layout 'blank'

  def new
    respond_to do |format|
      format.html
      format.js {}
    end
  end

  def create
    @auto_task = AutoTask.new(task_params)
    authorize @auto_task

    @auto_task.user = current_user

    if @auto_task.save
      respond_to do |format|
        format.html
        format.js {}
      end
    else
      respond_to do |format|
        format.html
        format.js { render 'failed.js.erb' }
      end
    end
  end

  def edit
    authorize @auto_task

    respond_to do |format|
      format.html
      format.js {}
    end
  end

  def update
    authorize @auto_task

    if @auto_task.update(task_params)
      respond_to do |format|
        format.html
        format.js {}
      end
    else
      respond_to do |format|
        format.html
        format.js { render 'failed.js.erb' }
      end
    end
  end

  def destroy
    authorize @auto_task

    @auto_task.destroy!

    respond_to do |format|
      format.js {}
    end
  end

  def reposition
    positions = position_params[:positions].split(',')
    authorize positions, policy_class: AutoTaskPolicy

    AutoTask.reposition(positions)

    respond_to do |format|
      format.json { head :no_content, status: :ok }
    end
  end

  private

  def task_params
    params.require(:auto_task).permit(:title, :notes, :days_until_due)
  end

  def position_params
    params.require(:auto_task).permit(:positions)
  end

  def set_auto_task
    @auto_task = AutoTask.find(params[:id])
  end
end
