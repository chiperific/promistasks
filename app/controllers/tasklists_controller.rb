# frozen_string_literal: true

class TasklistsController < ApplicationController
  layout 'blank'

  def push
    authorize @tasklist = Tasklist.find(params[:id])

    @tasklist.push_auto_tasks!

    respond_to do |format|
      format.js {}
    end
  end

  private

  def tasklist_params
    params.require(:tasklist).permit(:title, :google_id)
  end
end
