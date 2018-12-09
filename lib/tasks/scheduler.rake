# frozen_string_literal: true

desc "Email Scheduling Daemon"
task send_reminders: :environment do
  puts 'Scheduling the reminders to occur at 8am on weekdays'
  # PaymentReminderJob.set(cron: '0 8 * * 1-5').perform_later

  # Every 2 mins, for testing
  PaymentReminderJob.set(cron: '0-59/2 * * * *').perform_later
  puts 'Done'
end

task sync_w_api: :environment do
  puts 'Scheduling the sync to occur hourly'
  SyncUserWithApiJob.set(cron: @hourly).perform_later
  puts 'Done'
end
