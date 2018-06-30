# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit
  include ErrorHandler

  protect_from_forgery with: :exception
  after_action :verify_authorized, unless: :devise_controller?

  before_action :set_job_id_for_progress_bar_div
  before_action :set_return_path

  def set_job_id_for_progress_bar_div
    return false unless current_user
    job = current_user.jobs.where(completed_at: nil).last
    @job_id = job&.id || 0
  end

  def set_return_path
    back = request.referer.present? && request.fullpath != URI(request.referer).path ? request.referer : root_path
    @return_path = URI(back).path
  end
end
