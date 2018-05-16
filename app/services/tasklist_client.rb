# frozen_string_literal: true

class TasklistClient
  include HTTParty
  # require 'google/apis/tasks_v1'

  BASE_URI = 'https://www.googleapis.com/tasks/v1/users/@me/lists'

  # https://developers.google.com/tasks/v1/reference/

  def list(user)
    # Returns all the authenticated user's task lists.
    HTTParty.get(BASE_URI, headers: headers(user).as_json)
  end

  def get(user, tasklist)
    # Returns the authenticated user's specified task list.
    HTTParty.get(BASE_URI + '/' + tasklist.google_id, headers: headers(user).as_json)
  end

  def insert(user, tasklist)
    # Creates a new task list and adds it to the authenticated user's task lists.
    body = { title: tasklist.name }
    HTTParty.post(BASE_URI, { headers: headers(user).as_json, body: body.to_json })
  end

  def update(user, tasklist)
    # Modify the authenticated user's specified task list. This method supports patch semantics.
    body = { title: tasklist.name }
    HTTParty.patch(BASE_URI + '/' + tasklist.google_id, { headers: headers(user).as_json, body: body.to_json })
  end

  def delete(user, tasklist)
    # Deletes the authenticated user's specified task list.
    HTTParty.delete(BASE_URI + '/' + tasklist.google_id, headers: headers(user).as_json)
  end

  private

  def headers(user)
    { 'Authorization': 'OAuth ' + user.oauth_token,
      'Content-type': 'application/json'
    }
  end
end
