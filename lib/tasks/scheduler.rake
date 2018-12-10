# frozen_string_literal: true

desc "Email Scheduling Daemon"
task send_reminders: :environment do
  # puts 'Scheduling the reminders to occur at 8am on weekdays'
  # PaymentReminderJob.set(cron: '0 8 * * 1-5').perform_later

  # Every minute, for testing
  puts 'Scheduling the reminders to occur every minute for testing'
  Delayed::Job.enqueue(PaymentReminderJob.new, cron: '0-59 * * * *')
  # PaymentReminderJob.set().perform_later
  puts 'Done'
end

task sync_w_api: :environment do
  puts 'Scheduling the sync to occur hourly'

  User.oauth.select(:id).each do |user|
    Delayed::Job.enqueue(SyncUserWithApiJob.new(user.id), cron: @hourly)
  end
  # SyncUserWithApiJob.set(cron: @hourly).perform_later
  puts 'Done'
end
