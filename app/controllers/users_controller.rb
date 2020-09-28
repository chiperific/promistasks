# frozen_string_literal: true

class UsersController < ApplicationController
  def show
    authorize User

    @tasklists = current_user.tasklists.alphabetical
    @auto_tasks = current_user.auto_tasks.ordered
    @new_task = AutoTask.new
  end

  def destroy
    authorize current_user
    flash[:alert] = 'Delete triggered!'
    redirect_to root_url
  end

  def tasklists
    # return a list of all tasklists, EXCEPT default
  end
end
