# frozen_string_literal: true

class TasklistsClient
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def connect
    @user.refresh_token!
  end

  def count
    tl_json = fetch
    tl_json['items'].present? ? tl_json['items'].count : 0
  end

  def create_property(title, default)
    Property.create(
      name: title,
      creator: @user,
      is_default: default,
      is_private: true,
      created_from_api: true
    )
  end

  def fetch
    connect
    @user.list_api_tasklists
  end

  def fetch_default
    connect
    @user.fetch_default_tasklist
  end

  def handle_tasklist(tasklist_json, default = false)
    tasklist = Tasklist.where(user: @user, google_id: tasklist_json['id']).first_or_initialize
    if tasklist.new_record?
      tasklist.property = create_property(tasklist_json['title'], default)
      tasklist.save!
    else
      case tasklist.updated_at.utc < Time.parse(tasklist_json['updated'])
      when true
        # default tasklist can differ in name/title between API and this app
        update_property(tasklist.property, tasklist_json['title']) unless default
        tasklist.update(updated_at: tasklist_json['updated']) unless tasklist_json['updated'].nil?
      when false
        # default tasklist can differ in name/title between API and this app
        tasklist.api_update unless default
      end
    end
    tasklist.reload.id
  end

  def not_in_api
    tls_json = fetch
    items = tls_json['items'].present? ? tls_json['items'].map { |i| i['id'] } : 0
    Tasklist.where(user: @user).where.not(google_id: items)
  end

  def push
    pushable = not_in_api
    return false unless pushable.present?
    pushable.each(&:api_insert)
  end

  def sync
    tasklists_json = fetch
    return tasklists_json if tasklists_json.nil? || tasklists_json['errors'].present?
    default_id = fetch_default['id']
    tasklist_ids = []

    tasklists_json['items'].each do |tasklist_json|
      next if tasklist_json['id'] == default_id
      tasklist_ids << handle_tasklist(tasklist_json)
    end

    Tasklist.where(id: tasklist_ids.uniq)
  end

  def sync_default
    default_tasklist_json = fetch_default
    return default_tasklist_json if default_tasklist_json.nil? || default_tasklist_json['errors'].present?

    id = handle_tasklist(default_tasklist_json, true)

    Tasklist.find(id)
  end

  def update_property(property, title)
    property.tap do |prop|
      prop.name = title
      prop.creator_id ||= @user.id
      prop.save
    end
    property.reload
  end
end
