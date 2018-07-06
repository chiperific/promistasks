# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit
  include ErrorHandler

  protect_from_forgery with: :exception
  # after_action :verify_authorized, unless: :devise_controller?

  before_action :set_job_id_for_progress_bar_div
  before_action :set_notification_for_refresh

  after_action :save_old_params
  before_action :set_return_path

  def set_job_id_for_progress_bar_div
    return false unless current_user
    job = current_user.jobs.where(completed_at: nil).last
    @job_id = job&.id || 0
  end

  def set_notification_for_refresh
    @just_signed_in = ''
    @just_signed_in = 'pulse red lighten-2' if current_user && Time.now < current_user.current_sign_in_at + 30.seconds
  end

  def save_old_params
    return false if bad_params

    session[:pre_previous] = session[:previous] unless params_match(session[:previous], params)
    session[:previous] = params.dup
  end

  def set_return_path
    @view_previous = session[:previous]
    @view_pre_previous = session[:pre_previous]

    conditions =
      request.referer.present? &&
      request.fullpath != URI(request.referer).path

    back = conditions ? request.referer : properties_path
    back = build_url(session[:previous]) unless session[:previous].nil? || bad_params
    back = build_url(session[:pre_previous]) if session[:pre_previous].present? && params_match(session[:previous], params) && !bad_params

    @return_path = URI(back).path
  end

  def params_match(param1, param2)
    return false if param1.nil? || param2.nil?
    param1['controller'] == param2['controller'] &&
      param1['action']   == param2['action'] &&
      param1['id']       == param2['id'] &&
      param1['syncing']  == param2['syncing']
  end

  def bad_params
    params[:action] == 'current_user_id' ||
      params[:action] == 'alerts' ||
      params[:action] == 'google_oauth2' ||
      params[:action] == 'api_sync' ||
      params[:action] == 'clear_completed_jobs' ||
      params[:commit].present?
  end

  def build_url(param)
    url_for(
      controller: param['controller'],
      action: param['action'],
      id: param['id'],
      syncing: param['syncing']
    )
  end
end
