# frozen_string_literal: true

class GetPropertiesClient
  def initialize(user)
    user.refresh_token!

    tasklists = TasklistClient.new.list(user)

    tasklists['items'].each do |tasklist_json|
      property = Property.where(google_id: tasklist_json['id']).first_or_initialize

      property.assign_from_api_fields!(tasklist_json)
      property.creator ||= user
      property.save!
    end
  end
end
