# frozen_string_literal: true

class TasklistsController < ApplicationController
  def create; end

  def destroy; end

  private

  def tasklist_params
    params.require(:tasklist).permit(:title, :google_id)
  end
end
