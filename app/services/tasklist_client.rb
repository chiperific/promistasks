# frozen_string_literal: true

class TasklistClient
  include HTTParty
  require 'google/apis/tasks_v1'

  BASE_URI = 'https://www.googleapis.com/tasks/v1/'

  # https://web.archive.org/web/20160829225627/https://developers.google.com/google-apps/tasks/v1/reference/

  def list_tasklists(user)
    # Returns all the authenticated user's task lists.
    HTTParty.get(BASE_URI + 'users/@me/lists', headers: headers(user))
  end

  def get_tasklist(user, tasklist)
    # Returns the authenticated user's specified task list.
    HTTParty.get(BASE_URI + 'users/@me/lists/' + tasklist.google_id, headers: headers(user))
  end

  def insert_tasklist(user, tasklist)
    # Creates a new task list and adds it to the authenticated user's task lists.
    body = {
      title: tasklist.title
    }

    HTTParty.post(BASE_URI + 'users/@me/lists', { headers: headers(user), body: body.to_json })
  end

  def update_tasklists(user, tasklist)
    # Modify the authenticated user's specified task list.
    # This method supports patch semantics.
    body = {
      title: tasklist.title
    }

    HTTParty.patch(BASE_URI + 'users/@me/lists/' + tasklist.google_id, { headers: headers(user), body: body.to_json })
  end

  def delete_tasklist(user, tasklist)
    # Deletes the authenticated user's specified task list.
    HTTParty.delete(BASE_URI + 'users/@me/lists/' + tasklist.google_id, headers: headers(user))
  end

  private

  def headers(user)
    { 'Authorization': 'OAuth ' + user.oauth_token }
  end
end
