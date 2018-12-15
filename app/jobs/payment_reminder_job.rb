# frozen_string_literal: true

class PaymentReminderJob < ApplicationJob
  require 'pry-remote'

  def initialize(*args)
    @staff = User.staff
  end

  def enqueue(job)
    job.record     = Organization.first
    job.identifier = 'payments_reminder_' + Time.now.utc.rfc3339(3)
  end

  def perform(*args)
    @staff.each do |staff|
      is_billing_contact = staff.id == Organization.first.billing_contact&.id
      should_send = (is_billing_contact && Payment.due_within(14).any?) ||
        Payment.due_within(14).related_to(staff).any?
      UserMailer.payments_reminder(staff, is_billing_contact).deliver_now if should_send
    end
  end
end
