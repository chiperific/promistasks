# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      sign_in @user
      if @user.created_at.strftime('%y-%m-%d-%H-%M') == @user.updated_at.strftime('%y-%m-%d-%H-%M')
        redirect_to edit_user_path(@user)
        flash[:success] = "Welcome #{current_user.fname}!<br />Please fill out your information."
      else
        redirect_to properties_path
        flash[:success] = "Welcome, #{current_user.fname}"
      end
    else
      session['devise.google_data'] = request.env['omniauth.auth'].except(:extra) # Removing extra as it can overflow some session stores
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path
    flash[:alert] = 'Failed to authenticate from Google.'
  end
end
