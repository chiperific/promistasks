# frozen_string_literal: true

class TaskClient
  include HTTParty
  require 'google/apis/tasks_v1'

  BASE_URI = 'https://www.googleapis.com/tasks/v1/'

  # https://web.archive.org/web/20160829225627/https://developers.google.com/google-apps/tasks/v1/reference/

  def list_task(user, tasklist)
    # Returns all tasks in the specified task list.
    HTTParty.get(BASE_URI + 'lists/' + tasklist.google_id + '/tasks/', headers: headers(user))
  end

  def get_task(user, tasklist, task)
    # Returns the specified task.
    HTTParty.get(BASE_URI + 'lists/' + tasklist.google_id + '/tasks/' + task.google_id, headers: headers(user))
  end

  def insert_task(user, tasklist, task)
    # Creates a new task on the specified task list.
    body = {
      status: task.status,
      title: task.title,
      notes: task.notes,
      due: task.due.utc.rfc3339(3),
      completed: task.completed.utc.rfc3339(3),
      deleted: task.deleted
    }
    HTTParty.post(BASE_URI + 'lists/' + tasklist.google_id + '/tasks/', { headers: headers(user), body: body.to_json })
  end

  def update_task(user, tasklist, task)
    # Modify the specified task.
    # This method supports patch semantics
    body = {
      status: task.status,
      title: task.title,
      notes: task.notes,
      due: task.due.utc.rfc3339(3),
      completed: task.completed.utc.rfc3339(3),
      deleted: task.deleted
    }
  HTTParty.patch(BASE_URI + 'lists/' + tasklist.google_id + '/tasks/' + task.google_id, { headers: headers(user), body: body.to_json })
  end

  def delete_task(user, tasklist, task)
    # Deletes the specified task from the task list.
    HTTParty.delete(BASE_URI + 'lists/' + tasklist.google_id + '/tasks/' + task.google_id, headers: headers(user))
  end

  def clear_tasks(user, tasklist)
    # Clears all completed tasks from the specified task list.
    # The affected tasks will be marked as 'hidden' and no longer be returned by default
    # when retrieving all tasks for a task list.
    HTTParty.post(BASE_URI + 'lists/' + tasklist.google_id + '/clear', headers: headers(user))
  end

  def move_task(user, tasklist, task, parent_id, previous_id)
    # Moves the specified task to another position in the task list.
    # This can include putting it as a child task under a new parent
    # and/or move it to a different position among its sibling tasks.

    # .../move?parent=&previous=
    # Omit parent if task is moved to top level
    # Omit previous if task is move to first position among siblings

    uri = BASE_URI + 'lists/' + tasklist.google_id + '/tasks/' + task.google_id + '/move'
    uri += '?' if parent_id.present? || previous_id.present?
    uri += 'parent=' + parent_id if parent_id.present?
    uri += 'previous=' + previous_id if previous_id.present?

    HTTParty.post(uri, headers: headers(user))
  end

  private

  def headers(user)
    { 'Authorization': 'OAuth ' + user.oauth_token }
  end
end
