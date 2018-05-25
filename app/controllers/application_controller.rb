class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :refresh_current_user_token

  def refresh_current_user_token
    current_user.refresh_token! if current_user
  end
end
