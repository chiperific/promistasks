# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'promise_tasks@familypromisegr.org'
  layout 'mailer'
end
