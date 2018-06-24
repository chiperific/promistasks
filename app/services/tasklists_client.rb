# frozen_string_literal: true

class TasklistsClient
  # think about breaking up methods for job:
  # connect(user) - just the refresh_token
  # fetch(user) - return the json blob
  # sync_default(user) - handle_tasklist(json, true)
  # sync(user) - handle_tasklist(json)
  # push(user) - push un-found tasklists via api_update
  # THEN I could:
  # - create an instance in the job
  # - get rid of self.methods
  # - go back to using @user from initialize
  # - would probably help with the tests too

  def self.pre_count(user)
    return false unless user.oauth_id.present?
    user.refresh_token!

    tasklists = user.list_api_tasklists
    @count = tasklists['items'].count

    @api_headers = { 'Authorization': 'OAuth ' + user.oauth_token, 'Content-type': 'application/json' }.as_json

    tasklists['items'].each do |tasklist|
      tasks = HTTParty.get('https://www.googleapis.com/tasks/v1/lists/' + tasklist['id'] + '/tasks/', headers: @api_headers)
      @count += tasks['items'].count
    end

    @count
  end

  def self.sync(user)
    @user = user
    return false unless user.oauth_id.present?
    user.refresh_token!

    @property_ary = []

    @default_tasklist_json = user.fetch_default_tasklist
    handle_tasklist(@default_tasklist_json, true)

    @tasklists = user.list_api_tasklists
    return false unless @tasklists.present?
    @tasklists['items'].each do |tasklist_json|
      handle_tasklist(tasklist_json)
    end

    Property.visible_to(@user).where.not(id: @property_ary.uniq).each do |property|
      property.tasklists.where(user: @user).first.api_insert
    end

    @property_ary.uniq
  end

  def self.handle_tasklist(tasklist_json, default = false)
    @user ||= User.first if Rails.env.test?
    @property_ary ||= [] if Rails.env.test?

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
        tasklist.api_update unless default
      end
    end
    @property_ary << tasklist.reload.property.id
  end

  def self.create_property(title, default = false)
    @user = User.first if Rails.env.test?
    Property.create(
      name: title,
      creator: @user,
      is_default: default,
      is_private: true,
      created_from_api: true
    )
  end

  def self.update_property(property, title)
    @user = User.first if Rails.env.test?
    property.tap do |prop|
      prop.name = title
      prop.creator ||= @user
      prop.save
    end
    property.reload
  end
end
