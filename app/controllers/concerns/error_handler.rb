# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  end

  def render_forbidden
    redirect_to in_path
  end

  def record_not_found
    flash[:alert] = 'Nothing was found'
    redirect_to root_path
  end
end
