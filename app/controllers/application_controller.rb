# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit
  include ErrorHandler

  protect_from_forgery with: :exception
  # after_action :verify_authorized, unless: :devise_controller?

  before_action :set_job_id_for_progress_bar_div

  after_action :save_old_params
  before_action :set_return_path

  def set_job_id_for_progress_bar_div
    return false unless current_user
    job = current_user.jobs.where(completed_at: nil).last
    @job_id = job&.id || 0
  end

  def save_old_params
    bad_params =
      params[:action] == 'current_user_id' ||
      params[:action] == 'alerts'

    return false if bad_params

    @@pre_previous = @@previous.dup if !params_match(@@previous, params)
    @@previous = params.dup
  end

  def set_return_path
    @@previous ||= nil
    @@pre_previous ||= nil

    @view_previous = @@previous.dup
    @view_pre_previous = @@pre_previous.dup

    conditions =
      request.referer.present? &&
      request.fullpath != URI(request.referer).path

    back = conditions ? request.referer : properties_path
    back = build_url(@@previous) if @@previous.present?
    back = build_url(@@pre_previous) if @@pre_previous.present? && params_match(@@previous, params)

    @return_path = URI(back).path
  end

  def params_match(param1, param2)
    return false if param1.nil? || param2.nil?
    param1[:controller] == param2[:controller] &&
      param1[:action]   == param2[:action] &&
      param1[:id]       == param2[:id] &&
      param1[:syncing]  == param2[:syncing]
  end

  def build_url(param)
    url_for controller: param[:controller], action: param[:action], id: param[:id], syncing: param[:syncing]
  end
end
