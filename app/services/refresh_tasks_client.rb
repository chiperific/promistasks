# frozen_string_literal: true

class RefreshTasksClient
  def initialize(user, tasklist_gid)
    tasks = TaskClient.new.list_tasks(user, tasklist_gid)

    tasks['items'].each do |task_json|
      task = Task.where( google_id: task_json['id'] ).first_or_initialize

      task.tap do |t|
        t.title = task_json['title']
        t.status = task_json['status']
        t.position = task_json['position']
      end

      task.save
    end
  end
end
