# frozen_string_literal: true

class PaymentReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts 'Creating user reminders'
    payments = Payment.due_within(14)
    users_ary = []
    users_ary << Organization.first.billing_contact

    payments_14.each do |pmt|
      users_ary << pmt.creator
    end

    users_ary.uniq.each do |user|
      assoc_payments = user.id == Organization.first.billing_contact&.id ?
        payments :
        payments.related_to(user)

      UserMailer.payment_reminder(user, assoc_payments).deliver_later if assoc_payments.any?
    end
  end
end
