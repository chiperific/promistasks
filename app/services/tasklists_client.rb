# frozen_string_literal: true

class TasklistsClient
  # what about properties that aren't a part of the tasklist json? E.g. deleted in Google?
  def initialize(user)
    user.refresh_token!
    @user = user
  end

  def self.sync(user)
    @default_tasklist_json = user.get_default_tasklist
    handle_default_tasklist
    @tasklists = user.list_api_tasklists
    return false unless @tasklists.present?
    iterate_tasklists
  end

  def handle_default_tasklist
    tasklist = Tasklist.where(user: @user, google_id: @default_tasklist_json['id']).first_or_initialize
    if tasklist.new_record?
      property = create_default_property(@default_tasklist_json)
      tasklist.property = property.reload
      tasklist.save!
    else
      case tasklist.updated_at.utc < Time.parse(@default_tasklist_json['updated'])
      when true
        update_property(@default_tasklist_json, tasklist.property, true)
        tasklist.update(updated_at: @default_tasklist_json['updated'])
      when false
        tasklist.api_update unless tasklist.property.name == @default_tasklist_json['title']
      end
    end
  end

  def iterate_tasklists
    @tasklists['items'].each do |tasklist_json|
      next if tasklist_json['id'] == @default_tasklist_json['id']
      property = Property.where(name: tasklist_json['title']).first_or_initialize
      if property.new_record?
        create_property(property)
        ensure_tasklist(property, tasklist_json['id'])
      else
        tasklist = ensure_tasklist(property, tasklist_json['id'])
        case property.updated_at.utc < Time.parse(tasklist_json['updated'])
        when true
          update_property(tasklist_json, property)
          tasklist.update(updated_at: @default_tasklist_json['updated'])
        when false
          tasklist.api_update unless tasklist.property.name == @default_tasklist_json['title']
        end
      end
      # stale tasklists (Google ID has changed for some reason)
      stale_tasklists = Tasklist.where.not(id: tasklist.id).where(property: property).where(user: @user)
      stale_tasklists.each(&:destroy) if stale_tasklists.any?
    end
  end

  def create_default_property(tasklist_json)
    Property.create(
      name: tasklist_json['title'],
      creator: @user,
      is_default: true,
      is_private: true,
      created_from_api: true
    )
  end

  def create_property(property)
    property.tap do |prop|
      prop.creator = @user
      prop.is_default = false
      prop.is_private = true
      prop.created_from_api = true
      prop.save
    end
  end

  def update_property(tasklist_json, property, is_default = false)
    property.tap do |prop|
      prop.name = tasklist_json['title']
      prop.creator ||= @user
      prop.is_default = is_default
    end
    property.save
    property.reload
  end

  def ensure_tasklist(property, tasklist_id)
    property.reload
            .tasklists
            .where(user: @user, google_id: tasklist_id)
            .first_or_create
  end
end
