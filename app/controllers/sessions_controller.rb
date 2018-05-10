# frozen_string_literal: true

class SessionsController < ApplicationController
  # before_action :updates_from_google

  # def create_from_google
  #   user = User.from_omniauth(request.env['omniauth.auth'])
  #   session[:user_id] = user.id
  #   redirect_to root_path
  # end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end

  private

  def updates_from_google
    # This might not be the right place for this, do I really want this to trigger when the user
    # For each certified User, do the following:
    # * Fetch tasklists && update the DB (or is this bad since tasklists == properties)
    # * Fetch tasks (iterate over each tasklist/property) && update the DB
  end
end
