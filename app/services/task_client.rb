# frozen_string_literal: true

class TaskClient
  include HTTParty
  # require 'google/apis/tasks_v1'

  BASE_URI = 'https://www.googleapis.com/tasks/v1/'

  # https://developers.google.com/tasks/v1/reference/

  def list(user, tasklist_gid)
    # Returns all tasks in the specified task list.
    HTTParty.get(BASE_URI + 'lists/' + tasklist_gid + '/tasks/', headers: headers(user).as_json)
  end

  def get(user, tasklist_gid, task_gid)
    # Returns the specified task.
    HTTParty.get(BASE_URI + 'lists/' + tasklist_gid + '/tasks/' + task_gid, headers: headers(user).as_json)
  end

  def insert(user, tasklist_gid, task)
    # Creates a new task on the specified task list.
    body = {
      status: task.status,
      title: task.title,
      notes: task.notes,
      deleted: task.deleted
    }

    # protect against errors generated when calling .utc on nil dates
    body[:due] = task.due.utc.rfc3339(3) if task.due.present?
    body[:completed] = task.completed_at.utc.rfc3339(3) if task.completed_at.present?

    HTTParty.post(BASE_URI + 'lists/' + tasklist_gid + '/tasks/', { headers: headers(user).as_json, body: body.to_json })
  end

  def update(user, tasklist_gid, task)
    # Modify the specified task. This method supports patch semantics
    body = {
      status: task.status,
      title: task.title,
      notes: task.notes,
      deleted: task.deleted
    }

    # protect against errors generated when calling .utc on nil dates
    body[:due] = task.due.utc.rfc3339(3) if task.due.present?
    body[:completed] = task.completed_at.utc.rfc3339(3) if task.completed_at.present?

    HTTParty.patch(BASE_URI + 'lists/' + tasklist_gid + '/tasks/' + task.google_id, { headers: headers(user).as_json, body: body.to_json })
  end

  def delete(user, tasklist_gid, task_gid)
    # Deletes the specified task from the task list.
    HTTParty.delete(BASE_URI + 'lists/' + tasklist_gid + '/tasks/' + task_gid, headers: headers(user).as_json)
  end

  def clear_complete(user, tasklist_gid)
    # Clears all completed tasks from the specified task list.
    # The affected tasks will be marked as 'hidden' and no longer be returned by default
    # when retrieving all tasks for a task list.
    HTTParty.post(BASE_URI + 'lists/' + tasklist_gid + '/clear', headers: headers(user).as_json)
  end

  def move(user, tasklist_gid, task_gid, parent_id, previous_id)
    # Moves the specified task to another position in the task list.
    # This can include putting it as a child task under a new parent
    # and/or move it to a different position among its sibling tasks.

    # .../move?parent=&previous=
    # Omit parent if task is moved to top level
    # Omit previous if task is move to first position among siblings

    uri = BASE_URI + 'lists/' + tasklist_gid + '/tasks/' + task_gid + '/move'
    uri += '?' if parent_id.present? || previous_id.present?
    uri += 'parent=' + parent_id if parent_id.present?
    uri += 'previous=' + previous_id if previous_id.present?

    HTTParty.post(uri, headers: headers(user).as_json)
  end

  def relocate(user, former_list, new_list, task)
    # Monkey patch to simulate moving to another list
  end

  private

  def headers(user)
    { 'Authorization': 'OAuth ' + user.oauth_token,
      'Content-type': 'application/json'
    }
  end
end
