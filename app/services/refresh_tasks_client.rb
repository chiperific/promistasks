# frozen_string_literal: true

class RefreshTasksClient
  def initialize(user, tasklist_gid)
    tasks = TaskClient.new.list_tasks(user, tasklist_gid)

    if tasks['items'].present?
      tasks['items'].each do |task_json|
        task = Task.where( google_id: task_json['id'] ).first_or_initialize

        task.tap do |t|
          t.title = task_json['title']
          # t.notes = task_json['notes']
          t.position = task_json['position']
          t.status = task_json['status']
          t.google_id = task_json['id']
          t.google_updated = task_json['updated']
          t.status = task_json['status']
        end

        task.creator = user if task.creator.nil?
        task.owner = user if task.owner.nil?
        task.save
      end
    end
  end
end
