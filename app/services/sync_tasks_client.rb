# frozen_string_literal: true

class SyncTasksClient
  def initialize(user, tasklist)
    user.refresh_token!

    tasks = tasklist.list_api_tasks

    return unless tasks['items'].present?

    tasks['items'].each do |task_json|
      task_user = TaskUser.where(google_id: task_json['id']).first_or_initialize

      if task_user.new_record?
        task = create_local_task(user, task_json, tasklist)
        create_local_task_user(user, task_json, task, task_user)
      else
        # compare dates, most recent wins
        case task_user.updated_at.utc < Time.parse(task_json['updated'])
        when true
          update_local_task(user, task_json, task_user, tasklist)
          update_local_task_user(user, task_json, task_user)
        when false
          update_google_task(user, task_user, tasklist.google_id)
        end
      end
    end
  end

  def create_local_task(user, task_json, tasklist)
    task = Task.new.assign_from_api_fields!(task_json)
    task.tap do |t|
      t.creator = user
      t.owner = user
      t.property = tasklist.property
      t.created_in_api = true
    end
    task.save
    task.reload
  end

  def create_local_task_user(user, task_json, task, task_user)
    task_user.user = user
    task_user.task = task
    task_user.assign_from_api_fields!(task_json)
    task_user.save
    task_user.reload
  end

  def update_local_task(user, task_json, task_user, tasklist)
    task_user.task.tap do |t|
      t.creator ||= user
      t.owner ||= user
      t.property = tasklist.property
      t.assign_from_api_fields!(task_json)
    end
    task.save
    task.reload
  end

  def update_local_task_user(user, task_json, task_user)
    task_user.task = task
    task_user.user = user
    task_user.assign_from_api_fields!(task_json)
    task_user.save
    task_user.reload
  end

  def update_google_task(user, task_user, tasklist_gid)
    response = TaskClient.new.update(
      user: user,
      task_user: task_user,
      tasklist_gid: tasklist_gid
    )
    task_user.update(
      google_id: response['id'],
      updated_at: response['updated']
    )
    task_user.reload
  end
end
