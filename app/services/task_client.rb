# frozen_string_literal: true

class TaskClient
  include HTTParty
  # require 'google/apis/tasks_v1'

  BASE_URI = 'https://www.googleapis.com/tasks/v1/lists/'

  # https://developers.google.com/tasks/v1/reference/

  def list(user, tasklist_gid)
    user.refresh_token!
    # Returns all tasks in the specified task list.
    HTTParty.get(BASE_URI + tasklist_gid + '/tasks/', headers: headers(user).as_json)
  end

  def get(user, tasklist_gid, task, task_gid)
    user.refresh_token!
    # Returns the specified task.
    HTTParty.get(BASE_URI + tasklist_gid + '/tasks/' + task_gid, headers: headers(user).as_json)
  end

  def insert(user, tasklist_gid, task)
    user.refresh_token!
    # Creates a new task on the specified task list.
    body = {
      title:     task.title,
      notes:     task.notes,
      status:    task.status,
      deleted:   task.deleted,
      completed: task.completed_at.present? ? task.completed_at.utc.rfc3339(3) : nil,
      due:       task.due.present? ? task.due.utc.rfc3339(3) : nil
    }

    HTTParty.post(BASE_URI + tasklist_gid + '/tasks/', { headers: headers(user).as_json, body: body.to_json })
  end

  def update(user, tasklist_gid, task, task_gid)
    user.refresh_token!
    # Modify the specified task. This method supports patch semantics
    body = {
      title:     task.title,
      notes:     task.notes,
      status:    task.status,
      deleted:   task.deleted,
      completed: task.completed_at.present? ? task.completed_at.utc.rfc3339(3) : nil,
      due:       task.due.present? ? task.due.utc.rfc3339(3) : nil
    }
    HTTParty.patch(BASE_URI + tasklist_gid + '/tasks/' + task_gid, { headers: headers(user).as_json, body: body.to_json })
  end

  def delete(user, tasklist_gid, task, task_gid)
    user.refresh_token!
    # Deletes the specified task from the task list.
    HTTParty.delete(BASE_URI + tasklist_gid + '/tasks/' + task_gid, headers: headers(user).as_json)
  end

  def clear_complete(user, tasklist_gid)
    user.refresh_token!
    # Clears all completed tasks from the specified task list.
    # The affected tasks will be marked as 'hidden' and no longer be returned by default
    # when retrieving all tasks for a task list.
    HTTParty.post(BASE_URI + tasklist_gid + '/clear', headers: headers(user).as_json)
  end

  def move(user, tasklist_gid, task, task_gid, options = {})
    user.refresh_token!
    # Moves the specified task to another position in the task list.
    # This can include putting it as a child task under a new parent
    # and/or move it to a different position among its sibling tasks.

    # .../move?parent=&previous=
    # Parent: make task a sub-task of the parent task, blank means directly in Tasklist
    # Previous: make task come after the previous task, blank means top of list

    uri = BASE_URI + tasklist_gid + '/tasks/' + task_gid + '/move?'
    uri += 'parent=' + options[:parent_id] if options[:parent_id].present?
    uri += '&' if options[:parent_id].present? && options[:previous_id].present?
    uri += 'previous=' + options[:previous_id] if options[:previous_id].present?

    HTTParty.post(uri, headers: headers(user).as_json)
  end

  def relocate(user, old_list_gid, new_list_gid, task, task_gid)
    user.refresh_token!
    # Moves the specified task to a different list.
    # Task is placed at the top of the list by default
    delete(user, old_list_gid, task, task_gid)
    insert(user, new_list_gid, task)
  end

  private

  def headers(user)
    { 'Authorization': 'OAuth ' + user.oauth_token,
      'Content-type': 'application/json'
    }
  end
end
