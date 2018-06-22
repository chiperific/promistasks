# frozen_string_literal: true

class SyncUserWithApiJob < ApplicationJob
  def initialize(user_id)
    @user = User.find(user_id)
  end

  def enqueue(job)
    job.record            = @user
    job.identifier        = 'user_' + @user.id.to_s + '_api_sync_' + Time.now.utc.rfc3339(3)
    job.progress_max      = Property.visible_to(@user).count + Task.visible_to(@user).count
  end

  def before(job)
    @job = job
  end

  def perform
    return false unless @user.oauth_id.present?
    @job.update_column(:message, 'Fetching your tasklists...')

    prop_ary = TasklistsClient.sync(@user)
    @job.update_columns(progress_current: prop_ary.length, progress_max: Task.visible_to(user).count + prop_ary.length)
    @job.update_column(:message, 'Processed ' + prop_ary.length.to_s + ' tasklists')

    task_ary = []
    @job.update_column(:message, 'Fetching your tasks...')
    Property.visible_to(@user).each do |property|
      tasklist = property.tasklists.where(user: self).first
      task_ary << TasksClient.sync(@user, tasklist)
    end

    @job.update_column(:message, 'Processed ' + task_ary.flatten.length.to_s + ' tasks')
    @job.update_columns(message: 'Done!', completed_at: Time.now)
  end
end
