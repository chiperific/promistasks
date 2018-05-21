# frozen_string_literal: true

class RefreshTasksClient
  def initialize(user, tasklist_gid, property_id)
    user.refresh_token if user.token_expired?

    tasks = TaskClient.new.list(user, tasklist_gid)

    if tasks['items'].present?
      tasks['items'].each do |task_json|
        task = Task.where( google_id: task_json['id'] ).first_or_initialize

        task.assign_from_api_fields(task_json)

        task.creator = user if task.creator.nil?
        task.owner = user if task.owner.nil?
        task.property_id = property_id

        task.save
      end
    end
  end
end
