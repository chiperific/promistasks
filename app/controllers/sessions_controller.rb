# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
    redirect_to user_path(current_user) if current_user
  end

  def create
    auth = request.env['omniauth.auth']

    user = User.from_omniauth(auth)
    reset_session
    session[:user_id] = user.id

    user.import_tasklists!

    flash[:notice] = "Welcome #{user.fname}!"
    redirect_to root_path
  end

  def destroy
    reset_session
    flash[:notice] = 'Signed out.'
    redirect_to in_path
  end

  def failure
    flash[:alert] = "Authentication error: #{params[:message].humanize}"
    redirect_to in_path
  end

end
