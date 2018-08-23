# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'familypromise@familypromisegr.org'
  layout 'mailer'
end
