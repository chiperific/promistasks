# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show authorization]

  def show
    authorize @user

    @tasklists = current_user.tasklists.alphabetical
    @auto_tasks = current_user.auto_tasks.ordered
    @new_task = AutoTask.new
  end

  def destroy
    authorize current_user
    flash[:alert] = 'Delete triggered!'
    redirect_to root_url
  end

  def authorization
    authorize @user

    respond_to do |format|
      format.html
      format.js { render 'authorization', layout: 'blank' }
    end
  end

  private

  def set_user
    @user = params[:id].present? ? User.find(params[:id]) : current_user
  end
end
