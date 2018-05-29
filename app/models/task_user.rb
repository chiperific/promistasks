# frozen_string_literal: true

class TaskUser < ApplicationRecord
  belongs_to :user, inverse_of: :task_joins
  belongs_to :task, inverse_of: :task_joins

  validates :user, :property, presence: true, uniqueness: true
  validates_uniqueness_of :google_id, allow_nil: true

  before_save :set_position_as_integer, if: -> { position.present? }
  after_validation :set_tasklist_id

  private

  def set_position_as_integer
    self.position_int = position.to_i
  end

  def set_tasklist_id
    self.tasklist_id = task.property.google_id
  end
end
