# frozen_string_literal: true

desc 'Scheduling Daemon'
task send_reminders: :environment do
  puts 'Cleaning up old Send Reminder syncs'
  Delayed::Job.where(record_type: 'Organization').delete_all
  puts 'Done'

  puts 'Scheduling the reminders to occur at 8am on weekdays'
  Delayed::Job.enqueue(PaymentReminderJob.new, cron: '0 8 * * 1-5')
  puts 'Done'
end

task sync_w_api: :environment do
  puts 'Cleaning up old User API syncs'
  Delayed::Job.where(record_type: 'User').delete_all
  puts 'Done'

  puts 'Scheduling the sync to occur hourly per user'
  User.oauth.pluck(:id).each do |user_id|
    Delayed::Job.enqueue(SyncUserWithApiJob.new(user_id), cron: @hourly)
  end
  puts 'Done'
end
