# frozen_string_literal: true

class TaskUser < ApplicationRecord
  include HTTParty

  belongs_to :user, inverse_of: :task_users
  belongs_to :task, inverse_of: :task_users

  validates :task, presence: true, uniqueness: { scope: :user }
  validates_uniqueness_of :google_id, allow_nil: true
  validates_inclusion_of :deleted, in: [true, false]

  before_validation :sequence_google_id, if: -> { Rails.env.test? }
  before_save :set_position_as_integer, if: -> { position.present? }
  after_validation :set_tasklist_gid, if: -> { tasklist_id.nil? }
  after_save :cascade_completeness, if: -> { completed_at.present? && task.completed_at.nil? }

  scope :descending, -> { undiscarded.order(position_int: :asc) }

  BASE_URI = 'https://www.googleapis.com/tasks/v1/lists/'

  # api_relocate: just send api_delete with before saving tasklist_gid and api_insert after saving tasklist_gid
  # api_move: set or clear the new parent and previous before calling

  def sequence_google_id
    return true if task&.title == 'validate'
    number = TaskUser.count.positive? ? TaskUser.last.id + 1 : 1
    self.google_id += number.to_s unless google_id.nil?
  end

  def assign_from_api_fields!(task_json)
    return false if task_json.nil?

    tap do |t|
      t.google_id = task_json['id']
      t.position = task_json['position']
      t.parent_id = task_json['parent']
      t.deleted = task_json['deleted'] || false
      t.completed_at = task_json['completed']
      t.updated_at = task_json['updated']
    end

    self
  end

  def api_get
    return false unless user.oauth_id.present?
    user.refresh_token!
    HTTParty.get(BASE_URI + tasklist_gid + '/tasks/' + google_id, headers: api_headers.as_json)
  end

  def api_insert
    return false unless user.oauth_id.present?
    user.refresh_token!
    HTTParty.post(BASE_URI + tasklist_gid + '/tasks/', { headers: api_headers.as_json, body: api_body.to_json })
  end

  def api_update
    return false unless user.oauth_id.present?
    user.refresh_token!
    HTTParty.patch(BASE_URI + tasklist_id + '/tasks/' + google_id, { headers: api_headers.as_json, body: api_body.to_json })
  end

  def api_delete
    return false unless user.oauth_id.present?
    user.refresh_token!
    HTTParty.delete(BASE_URI + tasklist_gid + '/tasks/' + google_id, headers: api_headers.as_json)
  end

  def api_move
    return false unless user.oauth_id.present?
    user.refresh_token!

    uri = BASE_URI + tasklist_gid + '/tasks/' + google_id + '/move?'
    uri += 'parent=' + parent_id if parent_id.present?
    uri += '&' if parent_id.present? && previous_id.present?
    uri += 'previous=' + previous_id if previous_id.present?

    HTTParty.post(uri, headers: api_headers.as_json)
  end

  private

  def set_position_as_integer
    self.position_int = 0 if position.nil?
    self.position_int = position.to_i
  end

  def set_tasklist_gid
    return false if user.nil? || task.nil?
    task.property.create_tasklist_for(user)
    tasklist = task.property.tasklists.where(user: user).first
    self.tasklist_gid = tasklist.google_id
  end

  def cascade_completeness
    task.update(completed_at: completed_at)
  end

  def api_headers
    { 'Authorization': 'OAuth ' + user.oauth_token,
      'Content-type': 'application/json' }
  end

  def api_body
    {
      title:     task.title,
      notes:     task.notes,
      status:    task.completed_at.present? ? 'completed' : 'needsAction',
      deleted:   task_user.deleted,
      completed: task.completed_at.present? ? task.completed_at.utc.rfc3339(3) : nil,
      due:       task.due.present? ? task.due.utc.rfc3339(3) : nil
    }
  end
end
