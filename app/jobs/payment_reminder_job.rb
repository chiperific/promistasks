# frozen_string_literal: true

class PaymentReminderJob < ApplicationJob
  require 'pry-remote'
  queue_as :default

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
    @job.upate_columns(message: @job.message + '; Creating user reminders')

    @job.update_columns(message: @job.message + '; Sending reminders for ' + @users_ary.count.to_s + ' users')
    @users_ary.uniq.each do |user|
      assoc_payments = user.id == Organization.first.billing_contact&.id ?
        payments :
        payments.related_to(user)

      @job.update_columns(message: @job.message + '; ' + user.name + ': ' + assoc_payments.count.to_s + ' pmts')
      UserMailer.payments_reminder(user, assoc_payments).deliver_later if assoc_payments.any?
    end
  end
end
