# frozen_string_literal: true

class RefreshPropertiesClient
  def initialize(user)
    tasklists = TasklistClient.new.list_tasklists(user)

    tasklists['items'].each do |tasklist|
      property = Property.where( google_id: tasklist['id'] ).first_or_initialize

      property.tap do |t|
        t.name = tasklist['title']
        t.selflink = tasklist['selfLink']
      end

      property.save
      RefreshTasksClient.new(user, property.reload.google_id)
    end
  end
end
