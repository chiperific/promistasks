# frozen_string_literal: true

class TasklistsClient
  # what about properties that aren't a part of the tasklist json? E.g. deleted in Google?

  def initialize(user)
    @user = User.find(user.id)
  end

  def sync
    return false unless @user.oauth_id.present?
    @user.refresh_token!
    @default_tasklist_json = @user.fetch_default_tasklist
    handle_tasklist(@default_tasklist_json, true)

    @tasklists = @user.list_api_tasklists
    return false unless @tasklists.present?
    @tasklists['items'].each do |tasklist_json|
      handle_tasklist(tasklist_json)
    end
  end

  def handle_tasklist(tasklist_json, default = false)
    tasklist = Tasklist.where(user: @user, google_id: tasklist_json['id']).first_or_initialize
    if tasklist.new_record?
      property = create_property(tasklist_json['title'], default)
      tasklist.property = property.reload
      tasklist.save!
    else
      case tasklist.updated_at.utc < Time.parse(tasklist_json['updated'])
      when true
        update_property(tasklist_json, tasklist.property, default)
        tasklist.update(updated_at: tasklist_json['updated'])
      when false
        tasklist.api_update unless tasklist.property.name == tasklist_json['title']
      end
    end
  end

  def create_property(title, default = false)
    Property.create(
      name: title,
      creator: @user,
      is_default: default,
      is_private: true,
      created_from_api: true
    )
  end

  def update_property(tasklist_json, property, default = false)
    property.tap do |prop|
      prop.name = tasklist_json['title']
      prop.creator ||= @user
      prop.is_default = default
      prop.save
    end
    property.reload
  end
end
