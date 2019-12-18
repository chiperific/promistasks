# frozen_string_literal: true

class TaskUser < ApplicationRecord
  include HTTParty

  belongs_to :user, inverse_of: :task_users
  belongs_to :task, inverse_of: :task_users

  validates :task, presence: true, uniqueness: { scope: :user }
  validates_presence_of :tasklist_gid, :scope
  validates_uniqueness_of :google_id, allow_nil: true, allow_blank: true
  validates_inclusion_of :deleted, in: [true, false]
  validates_inclusion_of :scope, in: Constant::TaskUser::SCOPE

  before_validation :set_tasklist_gid, if: -> { tasklist_gid.nil? }
  before_destroy    :api_delete
  before_create     :api_insert,              if: -> { user.present? && task.present? && google_id.blank? }
  after_update      :relocate,                if: -> { saved_change_to_tasklist_gid? }
  after_save        :elevate_completeness,    if: -> { completed_at.present? && task.completed_at.nil? }

  BASE_URI = 'https://www.googleapis.com/tasks/v1/lists/'

  def api_delete
    return false unless user.oauth_id.present? && google_id.present? && tasklist_gid.present?

    user.refresh_token!
    response = HTTParty.delete(BASE_URI + tasklist_gid + '/tasks/' + google_id, headers: api_headers.as_json)
    return false unless response.present?
  end

  def api_get
    return false unless user.oauth_id.present? && google_id.present? && tasklist_gid.present?

    user.refresh_token!
    response = HTTParty.get(BASE_URI + tasklist_gid + '/tasks/' + google_id, headers: api_headers.as_json)
    return false unless response.present?

    response
  end

  def api_insert
    # --->                                                        this keeps api_insert from duplicating the tasklist for the creator
    return false if user.oauth_id.blank? || tasklist_gid.blank? || (task.created_from_api? && user == task.creator && ((Time.now - 5.minutes)..Time.now).cover?(task.created_at))

    user.refresh_token!
    response = HTTParty.post(BASE_URI + tasklist_gid + '/tasks/', { headers: api_headers.as_json, body: api_body.to_json })
    return false unless response.present?

    response['id'] = sequence_google_id(response['id']) if Rails.env.test?

    # update_columns(google_id: response['id'], updated_at: response['updated'])
    self.google_id = response['id']
    self.updated_at = response['updated']
    response
  end

  def api_update
    return false unless user.oauth_id.present? && google_id.present? && tasklist_gid.present?

    user.refresh_token!
    response = HTTParty.patch(BASE_URI + tasklist_gid + '/tasks/' + google_id, { headers: api_headers.as_json, body: api_body.to_json })
    return false unless response.present?

    updated = response['updated'] || Time.now
    update_columns(updated_at: updated)
    response
  end

  def assign_from_api_fields(task_json)
    return false if task_json.nil?

    tap do |t|
      t.google_id = task_json['id']
      t.deleted = task_json['deleted'] || false
      t.completed_at = task_json['completed']
      t.updated_at = task_json['updated'] || Time.now
    end

    self
  end

  def tasklist
    Tasklist.where(google_id: tasklist_gid, user_id: user_id).first
  end

  private

  def api_body
    # don't allow brackets in notes, see Task#assign_from_api_fieds
    notes = task.notes.blank? ? '' : task.notes.tr('[', '(').tr(']', ')')
    notes += "[#{Constant::Task::PRIORITY[task.priority]}" if task.priority.present?
    notes += "[owner: #{task.owner.name} | creator: #{task.creator.name}]" unless task.creator == task.owner
    notes += "[budget remaining: #{task.budget_remaining.format}]" unless task.budget_remaining.nil?

    body = {
      title: task.title,
      notes: notes,
      status: task.completed_at.present? ? 'completed' : 'needsAction',
      deleted: deleted,
      completed: task.completed_at.present? ? task.completed_at.utc.rfc3339(3) : nil,
      due: task.due.present? ? task.due.rfc3339 : nil
    }

    body
  end

  def api_fields_are_present?
    user.oauth_id.present? && google_id.present? && tasklist_gid.present?
  end

  def api_headers
    { 'Authorization': 'OAuth ' + user.oauth_token,
      'Content-type': 'application/json' }
  end

  def elevate_completeness
    task.update(completed_at: completed_at)
  end

  def relocate
    return false if tasklist_gid_before_last_save == tasklist_gid

    mem_dup = dup
    mem_dup.tasklist_gid = tasklist_gid_before_last_save
    mem_dup.api_delete
    api_insert
  end

  def set_tasklist_gid
    return false if user.nil? || task.nil?

    tasklist = task.property.ensure_tasklist_exists_for(user)
    return false unless tasklist.present?

    self.tasklist_gid = tasklist.google_id
  end

  def sequence_google_id(response_id)
    return response_id if task&.title == 'validate'

    number = TaskUser.count.positive? ? TaskUser.last.id + 1 : 1
    response_id + number.to_s + Random.rand(0...3000).to_s
  end
end
