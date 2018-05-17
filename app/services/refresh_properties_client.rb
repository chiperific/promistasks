# frozen_string_literal: true

class RefreshPropertiesClient
  def initialize(user)
    user.refresh_token if user.token_expired?

    tasklists = TasklistClient.new.list(user)

    tasklists['items'].each do |tasklist_json|
      property = Property.where( google_id: tasklist_json['id'] ).first_or_initialize

      property.assign_from_api_fields(tasklist_json)

      property.save.reload

      RefreshTasksClient.new(user, property.google_id, property.id)
    end
  end
end
