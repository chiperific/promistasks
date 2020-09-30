# frozen_string_literal: true

class SyncJob
  include SuckerPunch::Job
  workers 1
  max_jobs 1

  def perform
    use_pooled_connection if working_hours?

    wait_time = working_hours? ? 3600 : 28_800

    WaitJob.perform_in(wait_time)
    puts "Next sync job scheduled for #{Time.now + wait_time.seconds}"
  end

  def working_hours?
    Date.today.on_weekday? && Time.now.hour.between?(9, 16)
  end

  def use_pooled_connection
    Rails.logger.silence do
      ActiveRecord::Base.connection_pool.with_connection do
        user_loop
      end
    end
  end

  def user_loop
    User.all.each do |user|
      puts "#{user.email}: Syncing"
      user.import_tasklists!
      user.tasklists.unsynced.each(&:push_auto_tasks!)
      puts "#{user.email}: Complete"
    rescue Exception => e
      puts "#{user.email}: Tried, failed: #{e}"
    end
  end
end
