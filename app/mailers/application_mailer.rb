# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  helper MailerHelper
  default from: 'promise_tasks@familypromisegr.org'
  layout 'mailer'
end
