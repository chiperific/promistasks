# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
    redirect_to '/auth/google'
  end

  def create
    auth = request.env['omniauth.auth']

    user = User.from_omniauth(auth)
    reset_session
    session[:user_id] = user.id

    Tasklist.import_for(user)

    flash[:notice] = "Welcome #{user.fname}!"
    redirect_to root_path
  end

  def destroy
    reset_session
    flash[:alert] = 'Signed out!'
    redirect_to root_path
  end

  def failure
    flash[:alert] = "Authentication error: #{params[:message].humanize}"
    redirect_to root_path
  end

end
