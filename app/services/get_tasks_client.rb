# frozen_string_literal: true

class GetTasksClient
  def initialize(user, tasklist_gid, property_id)
    user.refresh_token!

    tasks = TaskClient.new.list(user, tasklist_gid)
    return unless tasks['items'].present?

    tasks['items'].each do |task_json|
      task_user = TaskUser.where(google_id: task_json['id']).first_or_initialize

      if task_user.new_record?
        task = Task.where('title = ? AND property_id = ?', task_json['title'], property_id).first_or_initialize
      else
        task = task_user.task
      end

      task.assign_from_api_fields!(task_json)
      task.creator ||= user
      task.owner ||= user
      task.save

      task_user.tap do |t|
        t.user = user
        t.task = task
        t.tasklist_id = tasklist_gid
        t.position = task_json['position']
        t.parent_id = task_json['parent']
        t.save
      end
    end
  end
end
