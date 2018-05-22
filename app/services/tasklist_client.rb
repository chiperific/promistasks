# frozen_string_literal: true

class TasklistClient
  include HTTParty
  # require 'google/apis/tasks_v1'

  BASE_URI = 'https://www.googleapis.com/tasks/v1/users/@me/lists'

  # before_hook :refresh_user(user) # needs a variable

  # https://developers.google.com/tasks/v1/reference/

  def list(user)
    user.refresh_token!
    # Returns all the authenticated user's task lists.
    HTTParty.get(BASE_URI, headers: headers(user))
  end

  def get(user, tasklist)
    user.refresh_token!
    # Returns the authenticated user's specified task list.
    HTTParty.get(BASE_URI + '/' + tasklist.google_id, headers: headers(user))
  end

  def insert(user, tasklist)
    user.refresh_token!
    # Creates a new task list and adds it to the authenticated user's task lists.
    body = { title: tasklist.name }
    HTTParty.post(BASE_URI, { headers: headers(user), body: body.to_json })
  end

  def update(user, tasklist)
    user.refresh_token!
    # Modify the authenticated user's specified task list. This method supports patch semantics.
    body = { title: tasklist.name }
    HTTParty.patch(BASE_URI + '/' + tasklist.google_id, { headers: headers(user), body: body.to_json })
  end

  def delete(user, tasklist)
    user.refresh_token!
    # Deletes the authenticated user's specified task list.
    HTTParty.delete(BASE_URI + '/' + tasklist.google_id, headers: headers(user))
  end

  private

  def headers(user)
    { 'Authorization': 'OAuth ' + user.oauth_token,
      'Content-type': 'application/json' }.as_json
  end
end
