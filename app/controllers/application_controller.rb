# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit
  include ErrorHandler

  protect_from_forgery with: :exception
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
end
