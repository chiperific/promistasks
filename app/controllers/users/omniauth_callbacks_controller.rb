# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      # flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
      sign_in @user
      flash[:success] = "Welcome back, #{current_user.fname}"

      Delayed::Job.enqueue SyncUserWithApiJob.new(@user.id)
      redirect_to tasks_path
    else
      session['devise.google_data'] = request.env['omniauth.auth'].except(:extra) # Removing extra as it can overflow some session stores
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path
  end
end
