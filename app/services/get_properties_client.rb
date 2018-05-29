# frozen_string_literal: true

class GetPropertiesClient
  def initialize(user)
    user.refresh_token!

    tasklists = TasklistClient.new.list(user)

    tasklists['items'].each do |tasklist_json|
      property = Property.where(name: tasklist_json['title']).first_or_initialize
      property.creator ||= user
      property.save!

      property.tasklists.where(user: creator).first_or_create.tap do |t|
        t.google_id = tasklist_json['id']
        t.save!
      end
    end
  end
end
