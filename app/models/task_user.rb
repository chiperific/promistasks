# frozen_string_literal: true

class TaskUser < ApplicationRecord
  belongs_to :user, inverse_of: :task_users
  belongs_to :task, inverse_of: :task_users

  validates :task, presence: true, uniqueness: { scope: :user }
  validates_uniqueness_of :google_id, allow_nil: true

  before_save :set_position_as_integer, if: -> { position.present? }
  after_validation :set_tasklist_id, if: -> { tasklist_id.nil? }

  scope :descending, -> { undiscarded.order(position_int: :asc) }

  def assign_from_api_fields!(task_json)
    return false if task_json.nil?

    tap do |t|
      t.google_id = task_json['id']
      t.position = task_json['position']
      t.parent_id = task_json['parent']
    end

    task_json.present?
  end

  private

  def set_position_as_integer
    self.position_int = 0 if position.nil?
    self.position_int = position.to_i
  end

  def set_tasklist_id
    task.property.create_tasklist_for(user) if task.property.tasklists.where(user: user).empty?
    tasklist = task.property.tasklists.where(user: user).first
    self.tasklist_id = tasklist.google_id
  end
end
