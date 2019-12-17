# frozen_string_literal: true
require 'pry-remote'

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
    property = Property.where(name: title, is_default: default)
    .first_or_initialize

    if property.new_record?
      property.creator = @user
      property.is_private = true
      property.created_from_api = true
      property.save
    end

    property.reload
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
    # TODO: Somehow, somewhere in here, an error is happening
    # Job SyncUserWithApiJob (id=5425) FAILED (0 prior attempts) with ActiveRecord::NotNullViolation: PG::NotNullViolation:
    # ERROR:  null value in column "property_id" violates not-null constraint
    # DETAIL:  Failing row contains (22, 2, null, eHFkTG9UUkl3d1ZQcTdCOA, 2019-12-16 06:01:05.327147, 2019-12-16 06:01:05.327147).

    binding.remote_pry

    if tasklist.new_record?
      tasklist.property = create_property(tasklist_json['title'], default)

      tasklist.valid?
      if tasklist.errors[:property].include? "has already been taken"
        # Error: @messages={:property=>["has already been taken"]}
        # Situation: Tasklist exists that matches user and property, but :google_id is blank
        tl = Tasklist.where(user: @user, property: tasklist.property).first
        tl.google_id = tasklist_json['id']
        tl.save
      else
        tasklist.save
      end
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
    Tasklist.where(user: @user, google_id: tasklist_json['id']).first.id
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
