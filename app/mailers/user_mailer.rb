# frozen_string_literal: true

class UserMailer < ApplicationMailer
  require 'pry-remote'

  def payments_reminder(user, is_billing_contact)
    @user = user

    case is_billing_contact
    when true
      @pmt7 = Payment.due_within(7)
      @pmt14 = Payment.due_within(14) - @pmt7
    else
      @pmt7 = Payment.related_to(@user).due_within(7)
      @pmt14 = Payment.related_to(@user).due_within(14) - @pmt7
    end

    mail(to: @user.email, subject: '[PromiseTasks] Payment reminder')
  end
end
