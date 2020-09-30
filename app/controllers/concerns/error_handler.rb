# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
    rescue_from Pundit::NotDefinedError, with: :render_not_defined
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from Google::Apis::AuthorizationError, with: :render_authorization
  end

  def path
    current_user.present? ? root_path : in_path
  end

  def render_authorization
    flash[:alert] = 'Authentication Error!'
    redirect_to authorization_user_path(current_user)
  end

  def render_forbidden
    flash[:alert] = 'You are not allowed.'
    redirect_to path
  end

  def render_not_defined
    flash[:alert] = 'Please sign in.'
    redirect_to path
  end

  def record_not_found
    flash[:alert] = 'Nothing was found.'
    redirect_to path
  end
end
