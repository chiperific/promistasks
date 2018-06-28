# frozen_string_literal: true

class SyncUserWithApiJob < ApplicationJob
  def initialize(user_id)
    @user = User.find(user_id)
    @tasklists_client = TasklistsClient.new(@user)
  end

  def enqueue(job)
    job.record            = @user
    job.identifier        = 'user_' + @user.id.to_s + '_api_sync_' + Time.now.utc.rfc3339(3)
    job.progress_max      = 1000
    job.progress_current  = 0
    job.message           = 'Connecting to Google...'
  end

  def before(job)
    @job = job
  end

  def perform
    sleep 1 # catch connecting to Google message
    @job.update_columns(message: 'Assessing the situation...')

    # pre-fetch and count tasklists from Google and those missing from Google
    tls_fetch         = @tasklists_client.fetch
    tls_count         = @tasklists_client.count
    tls_count_missing = @tasklists_client.not_in_api.count
    tls_ids           = tls_fetch['items'].map { |i| i['id'] }

    # pre-fetch and count tasks from Google and those missing from Google
    t_count_ary = []
    t_count_missing_ary = []
    tls_ids.each do |gid|
      found = TasksClient.fetch_with_tasklist_gid_and_user(gid, @user)
      t_count_ary << found['items'].count
      missing = TasksClient.not_in_api_with_tasklist_gid_and_user(gid, @user)
      t_count_missing_ary << missing['items'].count
    end

    max = tls_count + t_count_ary.sum + tls_count_missing + t_count_missing_ary.sum
    progress = @job.progress_current
    @job.update_columns(progress_max: max, message: 'Assessment complete', progress_current: progress)
    sleep 1

    # process the default tasklist
    @job.update_columns(message: 'Fetching default tasklist...', progress_current: progress)
    sleep 1

    default_tasklist = @tasklists_client.sync_default
    progress += 1
    @job.update_columns(message: 'Default tasklist done', progress_current: progress)
    sleep 1

    # process the default tasklist's tasks
    @job.update_columns(message: 'Fetching default tasks...')
    sleep 1

    tc = TasksClient.new(default_tasklist)
    count = tc.count
    if count.positive?
      tc.sync
      msg = 'Processed ' + count.to_s + ' default task'.pluralize(count)
      progress += count
    else
      msg = 'No default tasks'
    end
    @job.update_columns(message: msg, progress_current: progress)
    sleep 1

    # process remaining tasklists





    @job.update_columns(message: 'Fetching properties...')
    sleep 2

    tasklists = @tasklists_client.sync
    progress += tls_count - 1
    @job.update_columns(message: 'Properties done', progress_current: progress)
    sleep 2

    tasklists.each do |t|
      @job.update_columns(message: 'Fetching property tasks...')
      sleep 2

      tc = TasksClient.new(t)
      tc.sync
      count = tc.count
      msg = 'Processed ' + count.to_s + '  task'.pluralize(count)
      progress += count
      @job.update_columns(message: msg, progress_current: progress)
      sleep 2

      @job.update_columns(message: 'Looking for missing tasks...')
      sleep 2

      missing = tc.not_in_api
      if missing.present?
        msg = 'Found ' + missing.count.to_s + ' missing task'.pluralize(missing.count)
        max = @job.progress_max + missing.count
        @job.update_columns(message: msg, progress_max: max)
        sleep 2

        tc.push
        msg = 'Processed ' + missing.count.to_s + ' missing task'.pluralize(missing.count)
        progress += missing.count
        @job.update_columns(message: msg, progress_current: progress)
      else
        @job.update_columns(message: 'No missing tasks!')
      end
      sleep 2
    end

    @job.update_columns(message: 'Property tasks done')
    sleep 2

    @job.update_columns(message: 'Looking for missing properties...')
    sleep 2

    missing_tasklists = @tasklists_client.not_in_api
    if missing_tasklists.present?
      msg = 'Found ' + missing_tasklists.count.to_s + ' missing property'.pluralize(missing_tasklists.count)
      max = @job.progress_max + missing_tasklists.count
      @job.update_columns(message: msg, progress_max: max)
      sleep 2

      tc.push
      msg = 'Processed ' + missing_tasklists.count.to_s + ' missing property'.pluralize(missing_tasklists.count)
      progress += missing_tasklists.count
      @job.update_columns(message: msg, progress_current: progress)

      # now do the tasks for that property missing.each do |t|
      @job.update_columns(message: 'Sending tasks from missing properties...')
      sleep 2

      missing_tasklists.each do |t|
        tc = TasksClient.new(t)
        tc.sync
        count = tc.count
        max = @job.progress_max + count
        msg = 'Collected ' + count.to_s + ' missing task'.pluralize(count)
        @job.update_columns(message: msg, progress_max: max)
        sleep 2

        msg = 'Sent ' + count.to_s + ' missing task'.pluralize(count)
        progress += count
        @job.update_columns(message: msg, progress_current: progress)
        sleep 2
      end
    else
      @job.update_columns(message: 'No missing properties!')
    end
    sleep 2

    progress = @job.progress_max
    @job.update_columns(message: 'Wrapping up...', progress_current: progress )
    sleep 2
    @job.update_columns(message: 'Done!')
    sleep 2
  end

  def max_attempts
    3
  end
end
