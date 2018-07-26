# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit
  include ErrorHandler
  include ApplicationHelper

  protect_from_forgery with: :exception

  # REMOVE BEFORE PRODUCTION
  after_action :verify_authorized, unless: :devise_controller?

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
    @just_signed_in = 'btn-floating btn-small pulse red lighten-2' if notification_worthy
  end

  def notification_worthy
    return false unless current_user.present?
    Time.now < current_user.current_sign_in_at + 1.minute &&
      current_user.jobs.empty?
  end

  def save_old_params
    return false if bad_param?(params)

    session[:pre_previous] = session[:previous] unless params_match?(session[:previous], params)
    session[:previous] = params.dup
  end

  def set_return_path
    @view_previous = session[:previous]
    @view_pre_previous = session[:pre_previous]

    conditions =
      request.referer.present? &&
      request.fullpath != URI(request.referer).path

    back = conditions ? request.referer : properties_path
    back = build_url(session[:previous]) unless bad_param?(session[:previous])
    back = build_url(session[:pre_previous]) if session[:pre_previous].present? && (params_match?(session[:previous], params) || bad_param?(session[:previous]))

    @return_path = URI(back).path
  end

  def params_match?(param1, param2)
    return false if param1.blank? || param2.blank?
    param1['controller'] == param2['controller'] &&
      param1['action']   == param2['action'] &&
      param1['id']       == param2['id'] &&
      param1['syncing']  == param2['syncing']
  end

  def bad_param?(param)
    return true if param.blank?
    (Constant::Params::ACTIONS.include? param['action']) ||
      param['commit'].present? ||
      param['controller'] == 'sessions'
  end

  def build_url(param)
    return root_path if param.nil?
    # CLEAR out the old controller & action vars since url_for will append when nested
    # https://apidock.com/rails/ActionDispatch/Routing/UrlFor/url_for
    url_options[:_recall][:controller] = nil
    url_options[:_recall][:action] = nil
    url_for(
      controller: param['controller'],
      action: param['action'],
      id: param['id'],
      syncing: param['syncing'],
      filter: param['filter']
    )
  rescue ActionController::UrlGenerationError
    '/properties'
  end
end
