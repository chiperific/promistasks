# frozen_string_literal: true

class TaskUser < ApplicationRecord
  include HTTParty

  belongs_to :user, inverse_of: :task_users
  belongs_to :task, inverse_of: :task_users

  validates :task, presence: true, uniqueness: { scope: :user }
  validates_presence_of :tasklist_gid
  validates_uniqueness_of :google_id, allow_nil: true
  validates_inclusion_of :deleted, in: [true, false]

  before_validation :set_tasklist_gid, if: -> { tasklist_gid.nil? }
  before_save       :set_position_as_integer, if: -> { position.present? }
  before_destroy    :api_delete
  after_create      :api_insert,              unless: -> { task&.created_from_api? }
  after_update      :relocate,                if: -> { saved_change_to_tasklist_gid? }
  after_update      :api_move,                if: -> { saved_changes_to_placement? }
  after_save        :elevate_completeness,    if: -> { completed_at.present? && task.completed_at.nil? }

  scope :descending, -> { undiscarded.order(position_int: :asc) }
  scope :previous, ->(position_int) { where('position_int < ?', position_int).order(position_int: :desc) }

  BASE_URI = 'https://www.googleapis.com/tasks/v1/lists/'

  def assign_from_api_fields(task_json)
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

  def saved_changes_to_placement?
    !!saved_change_to_position? ||
      !!saved_change_to_parent_id? ||
      !!saved_change_to_previous_id?
  end

  def api_get
    return false unless user.oauth_id.present? && google_id.present? && tasklist_gid.present?
    user.refresh_token!
    response = HTTParty.get(BASE_URI + tasklist_gid + '/tasks/' + google_id, headers: api_headers.as_json)
    return false unless response.present?
    response
  end

  def api_insert
    return false unless user.oauth_id.present? && tasklist_gid.present?
    user.refresh_token!
    response = HTTParty.post(BASE_URI + tasklist_gid + '/tasks/', { headers: api_headers.as_json, body: api_body.to_json })
    return false unless response.present?
    response['id'] = sequence_google_id(response['id']) if Rails.env.test?

    update_columns(google_id: response['id'], updated_at: response['updated'], position: response['position'], parent_id: response['parent'])
    response
  end

  def api_update
    return false unless user.oauth_id.present? && google_id.present? && tasklist_gid.present?
    user.refresh_token!
    response = HTTParty.patch(BASE_URI + tasklist_gid + '/tasks/' + google_id, { headers: api_headers.as_json, body: api_body.to_json })
    return false unless response.present?
    update_columns(updated_at: response['updated'], position: response['position'], parent_id: response['parent'])
    response
  end

  def api_delete
    return false unless user.oauth_id.present? && google_id.present? && tasklist_gid.present?
    user.refresh_token!
    response = HTTParty.delete(BASE_URI + tasklist_gid + '/tasks/' + google_id, headers: api_headers.as_json)
    return false unless response.present?
  end

  def api_move
    # set or clear the new parent and previous before calling
    # what about when position changes? Must get precursing task's id and set to previous_id
    return false unless user.oauth_id.present? && google_id.present? && tasklist_gid.present?
    return false if position.nil? && parent_id.nil? && previous_id.nil?
    user.refresh_token!

    uri = BASE_URI + tasklist_gid + '/tasks/' + google_id + '/move?'
    uri += 'parent=' + parent_id if parent_id.present?
    uri += '&' if parent_id.present? && previous_id.present?
    uri += 'previous=' + previous_id if previous_id.present?

    response = HTTParty.post(uri, headers: api_headers.as_json)
    return false unless response.present?

    # then get rid of the previous_id as a move in the API will negate it
    self.update_column(previous_id: nil)

    response
  end

  private

  def sequence_google_id(response_id)
    return response_id if task&.title == 'validate'
    number = TaskUser.count.positive? ? TaskUser.last.id + 1 : 1
    response_id + number.to_s + Random.rand(0...3000).to_s
  end

  def set_position_as_integer
    self.position_int = 0 if position.nil?
    self.position_int = position.to_i
  end

  def set_tasklist_gid
    return false if user.nil? || task.nil?
    tasklist = task.property.ensure_tasklist_exists_for(user)
    return false unless tasklist.present?
    self.tasklist_gid = tasklist.google_id
  end

  def elevate_completeness
    task.update(completed_at: completed_at)
  end

  def relocate
    return false if tasklist_gid_before_last_save == tasklist_gid
    mem_dup = self.dup
    mem_dup.tasklist_gid = tasklist_gid_before_last_save
    mem_dup.api_delete
    self.api_insert
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
      deleted:   self.deleted,
      completed: task.completed_at.present? ? task.completed_at.utc.rfc3339(3) : nil,
      due:       task.due.present? ? task.due.utc.rfc3339(3) : nil
    }
  end
end
