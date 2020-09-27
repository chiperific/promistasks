# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit
  include ErrorHandler
  include ApplicationHelper

  # protect_from_forgery with: :exception

  # REMOVE BEFORE PRODUCTION
  after_action :verify_authorized
end
