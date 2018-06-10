# frozen_string_literal: true

class SyncTasklistsClient
  def initialize(user)
    user.refresh_token!

    tasklists = TasklistClient.new.list(user)
    return unless tasklists['items'].present?

    tasklists['items'].each do |tasklist_json|
      tasklist = Tasklist.where(google_id: tasklist_json['id']).first_or_initialize

      if tasklist.new_record?
        property = create_local_property(user, tasklist_json)
        create_local_tasklist(user, tasklist_json, property, tasklist)
      else
        # compare dates, most recent wins
        case tasklist.updated_at.utc < Time.parse(tasklist_json['update'])
        when true
          update_local_property(user, tasklist_json, tasklist.property)
          update_local_tasklist(user, tasklist_json, tasklist)
        when false
          update_google_tasklist(user, tasklist)
        end
        # stale lists (Google ID has changed for some reason)
        stale_tasklists = Tasklist.where.not(id: tasklist.id).where(property: tasklist.property).where(user: user)
        stale_tasklists.destroy_all if stale_lists.any?
      end
    end
  end

  def create_local_property(user, tasklist_json)
    property = Property.create(
      name: tasklist_json['title'],
      creator: user
    )
    property.reload
  end

  def create_local_tasklist(user, tasklist_json, property, tasklist)
    tasklist.tap do |t|
      t.property = property
      t.user = user
      t.google_id = tasklist_json['id']
      t.updated_at = tasklist_json['updated']
    end
    tasklist.save
    tasklist.reload
  end

  def update_local_property(user, tasklist_json, property)
    property.tap do |prop|
      prop.name = tasklist_json['title']
      prop.creator ||= user
    end
    property.save
    property.reload
  end

  def update_local_tasklist(user, tasklist_json, tasklist)
    tasklist.tap do |t|
      t.user ||= user
      t.property = property
      t.google_id = tasklist_json['id']
      t.updated_at = tasklist_json['updated']
    end
    tasklist.save
    tasklist.reload
  end

  def update_google_tasklist(user, tasklist)
    response = TasklistClient.new.update(user, tasklist)
    tasklist.update(
      google_id: response['id'],
      updated_at: response['updated']
    )
    tasklist.reload
  end
end
