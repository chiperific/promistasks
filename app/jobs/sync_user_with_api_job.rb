# frozen_string_literal: true

class SyncUserWithApiJob < ApplicationJob
  def initialize(user_id)
    @user = User.find(user_id)
    @tlc = TasklistsClient.new(@user)
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
    @progress = @job.progress_current
  end

  def max_attempts
    1
  end

  def pause
    sleep 1 unless Rails.env.test?
  end

  def oauth_creds_exist
    @user.oauth_id.present? &&
      @user.oauth_token.present? &&
      @user.oauth_refresh_token.present?
  end

  def perform
    pause

    if oauth_creds_exist == true
      determine_progress_max

      return if @job.error_message = 'cred_error'

      pause

      default_tasklist = process_tasklists(default: true)
      pause

      @job.update_columns(message: 'Fetching default tasks')
      pause

      process_tasks(default_tasklist, default: true)
      pause

      tasklists = process_tasklists
      pause

      tasklists.each_with_index do |t, i|
        i += 1
        msg = 'Fetching ' + i.ordinalize + ' property\'s tasks...'
        @job.update_columns(message: msg)
        pause

        process_tasks(t)
        pause
      end

      missing_tasklists = find_tasklists
      if missing_tasklists.present?
        msg = 'Found ' + missing_tasklists.count.to_s + ' missing property'.pluralize(missing_tasklists.count)
        @job.update_columns(message: msg)
        pause

        push_tasklists

        missing_tasklists.each_with_index do |t, i|
          tc = TasksClient.new(t)
          push_from_app(tc)
          pause
        end
      else
        @job.update_columns(message: 'No missing properties!')
      end
      pause

      wrap_up
      pause
    else
      @job.update_columns(message: 'Credential error!')
      pause
    end
  end

  def determine_progress_max
    @job.update_columns(message: 'Assessing the situation...')
    pause

    @job.update_columns(message: 'Fetching your tasklists from Google')

    tlc_list = @tlc.fetch

    if tlc_list['error']
      @job.update_columns(message: 'Credential error!')
      @job.update_columns(error_message: 'cred_error')
      return
    end

    tls_count = @tlc.count
    message = 'Found ' + tls_count.to_s + ' tasklist'.pluralize(tls_count)
    @job.update_columns(message: message)

    tls_count_missing = @tlc.not_in_api.count
    message = 'Found ' + tls_count_missing.to_s + ' missing tasklist'.pluralize(tls_count_missing)
    @job.update_columns(message: message)

    tls_ids = tlc_list['items'].map { |i| i['id'] }

    t_count_ary = []
    t_count_missing_ary = []
    tls_ids.each do |gid|
      found = TasksClient.fetch_with_tasklist_gid_and_user(gid, @user)
      t_count_ary << found['items'].count if found.present? && found['items'].present?
      missing = TasksClient.not_in_api_with_tasklist_gid_and_user(gid, @user)
      t_count_missing_ary << missing.count if missing.present?
    end
    max = tls_count + t_count_ary.sum + tls_count_missing + t_count_missing_ary.sum
    @job.update_columns(progress_max: max, message: 'Assessment complete', progress_current: @progress)
  end

  def process_tasklists(default: false)
    msg = default ? 'Fetching default tasklist...' : 'Fetching properties...'
    @job.update_columns(message: msg)
    pause

    tasklists = default ? @tlc.sync_default : @tlc.sync
    @progress += default ? 1 : @tlc.count - 1
    msg = default ? 'Default tasklist done' : 'Properties done'
    @job.update_columns(message: msg, progress_current: @progress)

    tasklists
  end

  def find_tasklists
    @job.update_columns(message: 'Looking for missing properties...')
    pause

    @tlc.not_in_api
  end

  def push_tasklists
    @tlc.push
    missing_tasklists = find_tasklists
    msg = 'Sent ' + missing_tasklists.count.to_s + ' missing property'.pluralize(missing_tasklists.count)
    @progress += missing_tasklists.count
    @job.update_columns(message: msg, progress_current: @progress)
  end

  def process_tasks(tasklist, default: false)
    tc = TasksClient.new(tasklist)

    fetch_from_api(tc, default)
    pause

    @job.update_columns(message: 'Looking for missing tasks...')
    pause

    push_from_app(tc)
  end

  def fetch_from_api(tasks_client, default)
    count = tasks_client.count
    if count.positive?
      tasks_client.sync
      msg = 'Processed ' + count.to_s + '  task'.pluralize(count)
      @progress += count
    else
      msg = default ? 'No default tasks' : 'No tasks'
    end
    @job.update_columns(message: msg, progress_current: @progress)
  end

  def push_from_app(tasks_client)
    missing = tasks_client.not_in_api
    if missing.present?
      msg = 'Found ' + missing.count.to_s + ' missing task'.pluralize(missing.count)
      @job.update_columns(message: msg)
      pause

      tasks_client.push
      msg = 'Sent ' + missing.count.to_s + ' missing task'.pluralize(missing.count)
      @progress += missing.count
      @job.update_columns(message: msg, progress_current: @progress)
    else
      @job.update_columns(message: 'No missing tasks!')
    end
  end

  def wrap_up
    @progress = @job.progress_max
    @job.update_columns(message: 'Wrapping up...', progress_current: @progress)
    pause
    @job.update_columns(message: 'Done!')
  end
end
