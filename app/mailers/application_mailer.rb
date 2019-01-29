# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  helper MailerHelper
  default from: 'taskmanager@familypromisegr.org'
  layout 'mailer'
end
