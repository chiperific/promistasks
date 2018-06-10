# frozen_string_literal: true

class TaskUser < ApplicationRecord
  belongs_to :user, inverse_of: :task_users
  belongs_to :task, inverse_of: :task_users

  validates :task, presence: true, uniqueness: { scope: :user }
  validates_uniqueness_of :google_id, allow_nil: true
  validates_inclusion_of :deleted, in: [true, false]

  before_validation :sequence_google_id, if: -> { Rails.env.test? }
  before_save :set_position_as_integer, if: -> { position.present? }
  after_validation :set_tasklist_id, if: -> { tasklist_id.nil? }
  after_save :cascade_completeness, if: -> { completed_at.present? && task.completed_at.nil? }

  scope :descending, -> { undiscarded.order(position_int: :asc) }

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

    task_json.present?
  end

  private

  def set_position_as_integer
    self.position_int = 0 if position.nil?
    self.position_int = position.to_i
  end

  def set_tasklist_id
    return false if user.nil? || task.nil?
    task.property.create_tasklist_for(user)
    tasklist = task.property.tasklists.where(user: user).first
    self.tasklist_id = tasklist.google_id
  end

  def cascade_completeness
    task.update(completed_at: completed_at)
  end
end
