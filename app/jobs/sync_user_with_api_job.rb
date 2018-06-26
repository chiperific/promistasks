# frozen_string_literal: true

class SyncUserWithApiJob < ApplicationJob
  def initialize(user_id)
    @user = User.find(user_id)
  end

  def enqueue(job)
    job.record            = @user
    job.identifier        = 'user_' + @user.id.to_s + '_api_sync_' + Time.now.utc.rfc3339(3)
    max                   = Property.visible_to(@user).count + Task.visible_to(@user).count + 1
    job.progress_max      = max == 1 ? 100 : max
    job.progress_current  = 1
    job.message           = 'Fetching your tasklists...'
  end

  def before(job)
    @job = job
  end

  def perform
    return false unless @user.oauth_id.present?
    sleep 2
    @job.update_column(:progress_max, TasklistsClient.pre_count(@user))
    sleep 2
    @prop_ary = TasklistsClient.sync(@user)
    @job.update_columns(progress_current: @prop_ary.length)
    @job.update_column(:message, 'Processed ' + @prop_ary.length.to_s + ' tasklists')
    sleep 1

    @task_ary = []
    @job.update_column(:message, 'Fetching your tasks...')
    sleep 1
    Property.visible_to(@user).each do |property|
      tasklist = property.tasklists.where(user: @user).first
      @task_ary << TasksClient.sync(@user, tasklist)
      @job.update_columns(progress_current: @task_ary.flatten.length + @prop_ary.length)
      @job.update_column(:message, 'Processed ' + @task_ary.flatten.length.to_s + ' tasks')
      sleep 1
    end

    finish = @job.progress_max
    @job.update_columns(progress_current: finish)
    @job.update_columns(message: 'Processed ' + @task_ary.flatten.length.to_s + @prop_ary.length.to_s + ' objects')
  end

  def max_attempts
    3
  end
end
