class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :refresh_token!

  def refresh_token
    current_user.refresh_token! if current_user
  end
end
