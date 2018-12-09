# frozen_string_literal: true

class UserMailer < ApplicationMailer
  # helper MailerHelper
  def payments_reminder(user, payments)
    @user = user

    @pmt7 = payments.due_within(7)
    @pmt14 = payments - @pmt7

    mail(to: @user.email, subject: '[PromiseTasks] Payment reminders')
  end
end
