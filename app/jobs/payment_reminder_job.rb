# frozen_string_literal: true

class PaymentReminderJob < ApplicationJob
  require 'pry-remote'

  def initialize(*args)
    @payments = Payment.due_within(14)
    @users_ary = []
    @users_ary << Organization.first.billing_contact

    @payments.each do |pmt|
      @users_ary << pmt.creator
    end
  end

  def enqueue(job)
    job.record     = Organization.first
    job.identifier = 'payments_reminder_' + Time.now.utc.rfc3339(3)
    job.message    = 'Initialized'
  end

  def before(job)
    @job = job
  end

  def perform(*args)
    @users_ary.uniq.each do |user|
      is_billing_contact = user.id == Organization.first.billing_contact&.id
      should_send = (is_billing_contact && Payment.due_within(14).any?) ||
        Payment.due_within(14).related_to(user).any?

      UserMailer.payments_reminder(user, is_billing_contact).deliver_now if should_send
    end
  end
end
