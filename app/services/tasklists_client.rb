# frozen_string_literal: true

class TasklistsClient
  def self.sync(user)
    @user = User.find(user.id)
    return false unless @user.oauth_id.present?
    @user.refresh_token!

    @property_ary = []

    @default_tasklist_json = @user.fetch_default_tasklist
    handle_tasklist(@default_tasklist_json, true)

    @tasklists = @user.list_api_tasklists
    return false unless @tasklists.present?
    @tasklists['items'].each do |tasklist_json|
      handle_tasklist(tasklist_json)
    end

    # what about properties that aren't a part of the tasklist json? E.g. deleted in Google?
    @property_ary
  end

  def self.handle_tasklist(tasklist_json, default = false)
    tasklist = Tasklist.where(user: @user, google_id: tasklist_json['id']).first_or_initialize
    if tasklist.new_record?
      property = create_property(tasklist_json['title'], default)
      tasklist.property = property.reload
      tasklist.save!
    else
      case tasklist.updated_at.utc < Time.parse(tasklist_json['updated'])
      when true
        # default tasklist can differ in name/title between API and this app
        update_property(tasklist.property, tasklist_json['title']) unless default
        tasklist.update(updated_at: tasklist_json['updated'])
      when false
        tasklist.api_update unless default
      end
    end
    @property_ary << tasklist.reload.property.id
  end

  def self.create_property(title, default = false)
    Property.create(
      name: title,
      creator: @user,
      is_default: default,
      is_private: true,
      created_from_api: true
    )
  end

  def self.update_property(property, title)
    property.tap do |prop|
      prop.name = title
      prop.creator ||= @user
      prop.save
    end
    property.reload
  end
end
