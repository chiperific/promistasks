# frozen_string_literal: true

class TasksClient
  def self.sync(user, tasklist)
    @user = user
    @tasklist = tasklist
    return false unless user.oauth_id.present? && tasklist.google_id.present?
    user.refresh_token!

    @task_ary = []

    @tasks = tasklist.list_api_tasks
    return false unless @tasks.present?

    @tasks['items'].each do |task_json|
      handle_task(task_json)
    end

    @tasklist.property.tasks.visible_to(@user).where.not(id: @task_ary).each do |task|
      tu = task.task_users.where(user: @user).first
      tu.api_insert unless tu.nil? || tu.google_id.present?
    end

    @task_ary
  end

  def self.handle_task(task_json)
    if Rails.env.test?
      @user ||= User.where(name: 'this').first
      @task_ary ||= []
      @tasklist ||= Tasklist.where(user: @user).first
      @user.save
      @tasklist.save
    end

    return false if task_json['title'] == ''
    task_user = TaskUser.where(google_id: task_json['id']).first_or_initialize
    if task_user.new_record?
      task_user.task = create_task(task_json)
      task_user = update_task_user(task_user, task_json)
    else
      case task_user.updated_at.utc < Time.parse(task_json['updated'])
      when true
        update_task(task_user.task, task_json)
        update_task_user(task_user, task_json)
      when false
        task_user.api_update
      end
    end
    @task_ary << task_user.reload.task.id
  end

  def self.create_task(task_json)
    task = Task.new
    task.tap do |t|
      t.creator = @user
      t.owner = @user
      t.property = @tasklist.property
      t.assign_from_api_fields(task_json)
    end
    task.save
    task.reload
  end

  def self.update_task(task, task_json)
    task.tap do |t|
      t.creator ||= @user
      t.owner ||= @user
      t.property = @tasklist.property
      t.assign_from_api_fields(task_json)
    end
    task.save!
    task.reload
  end

  def self.update_task_user(task_user, task_json)
    @user.save
    task_user.tap do |t|
      t.user = @user
      t.assign_from_api_fields(task_json)
      t.tasklist_gid = @tasklist.google_id
    end
    task_user.save!
    task_user.reload
  end
end
