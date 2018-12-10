# frozen_string_literal: true

desc "Email Scheduling Daemon"
task send_reminders: :environment do
  puts 'Scheduling the reminders to occur at 8am on weekdays'
  Delayed::Job.enqueue(PaymentReminderJob.new, cron: '0 8 * * 1-5')

  # puts 'Scheduling the reminders to occur immediately for testing'
  # Delayed::Job.enqueue(PaymentReminderJob.new)
  puts 'Done'
end

task sync_w_api: :environment do
  puts 'Scheduling the sync to occur hourly'
  User.oauth.select(:id).each do |user|
    Delayed::Job.enqueue(SyncUserWithApiJob.new(user.id), cron: @hourly)
  end

  # puts 'Scheduling the sync to occur immediately for testing'
  # User.oauth.select(:id).each do |user|
  #   Delayed::Job.enqueue(SyncUserWithApiJob.new(user.id))
  # end

  puts 'Done'
end
