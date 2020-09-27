# frozen_string_literal: true

class AutoTasksController < ApplicationController
  def create; end

  def update; end

  def destroy; end

  private

  def task_params
    params.require(:auto_task).permit(:title, :notes, :position, :days_until_due)
  end
end
