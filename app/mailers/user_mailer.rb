# frozen_string_literal: true

class UserMailer < ApplicationMailer
  require 'pry-remote'

  def payments_reminder(user, is_billing_contact)
    @user = user

    case is_billing_contact
    when true
      @pmt7 = Payment.due_within(7)
      @pmt14 = Payment.due_within(14) - @pmt7
      @pmt_late = Payment.past_due
    else
      @pmt7 = Payment.related_to(@user).due_within(7)
      @pmt14 = Payment.related_to(@user).due_within(14) - @pmt7
      @pmt_late = Payment.related_to(@user).past_due
    end

    mail(to: @user.email, subject: '[PromiseTasks] Payment reminder') if @pmt7.any? || @pmt14.any? || @pmt_late.any?
  end
end
