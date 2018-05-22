# frozen_string_literal: true

class GetTasksClient
  def initialize(user, tasklist_gid, property_id)
    user.refresh_token!

    tasks = TaskClient.new.list(user, tasklist_gid)
    return unless tasks['items'].present?

    tasks['items'].each do |task_json|
      task = Task.where(google_id: task_json['id']).first_or_initialize

      task.assign_from_api_fields(task_json)

      task.creator ||= user
      task.owner ||= user
      task.property_id = property_id

      task.save
    end
  end
end
