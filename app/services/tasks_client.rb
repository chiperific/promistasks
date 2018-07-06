# frozen_string_literal: true

class TasksClient
  attr_reader :tasklist
  attr_reader :user

  def initialize(tasklist)
    @tasklist = tasklist
    @user = @tasklist.user
  end

  def connect
    @user.refresh_token!
  end

  def fetch
    connect
    @tasklist.list_api_tasks
  end

  def self.fetch_with_tasklist_gid_and_user(google_id, user)
    return false unless user.oauth_token.present?
    user.refresh_token!

    api_header = { 'Authorization': 'OAuth ' + user.oauth_token,
                   'Content-type': 'application/json' }.as_json

    response = HTTParty.get('https://www.googleapis.com/tasks/v1/lists/' + google_id + '/tasks/', headers: api_header)
    response
  end

  def sync
    tasks_json = fetch
    return tasks_json if tasks_json.nil? || tasks_json['errors'].present?

    tasks_json['items'].each do |task_json|
      next if task_json['title'] == ''
      handle_task(task_json)
    end
  end

  def not_in_api
    tasks_json = fetch
    TaskUser.where(user: @user)
            .where(tasklist_gid: @tasklist.google_id)
            .where.not(google_id: tasks_json['items'].map { |i| i['id'] })
  end

  def self.not_in_api_with_tasklist_gid_and_user(google_id, user)
    tasks_json = fetch_with_tasklist_gid_and_user(google_id, user)
    items = tasks_json['items'].present? ? tasks_json['items'].map { |i| i['id'] } : 0
    TaskUser.where(user: @user)
            .where(tasklist_gid: google_id)
            .where.not(google_id: items)
  end

  def push
    pushable = not_in_api
    return false unless pushable.present?
    pushable.each(&:api_insert)
  end

  def count
    task_json = fetch
    task_json['items'].count
  end

  def handle_task(task_json)
    task_user = TaskUser.where(google_id: task_json['id']).first_or_initialize
    if task_user.new_record?
      task_user.task = create_task(task_json)
      update_task_user(task_user, task_json)
    else
      case task_user.updated_at.utc < Time.parse(task_json['updated'])
      when true
        update_task(task_user.task, task_json)
        update_task_user(task_user, task_json)
      when false
        task_user.api_update
      end
    end
  end

  def create_task(task_json)
    task = Task.create.tap do |t|
      t.creator_id = @user.id
      t.owner_id = @user.id
      t.property_id = @tasklist.property.id
      t.assign_from_api_fields(task_json)
    end
    task.save!
    task.reload
  end

  def update_task(task, task_json)
    task.tap do |t|
      t.creator_id ||= @user.id
      t.owner_id ||= @user.id
      t.property_id = @tasklist.property.id
      t.assign_from_api_fields(task_json)
    end
    task.save!
    task.reload
  end

  def update_task_user(task_user, task_json)
    task_user.tap do |t|
      t.user_id = @user.id
      t.assign_from_api_fields(task_json)
      t.tasklist_gid = @tasklist.google_id
    end
    task_user.save!
    task_user.reload
  end
end
