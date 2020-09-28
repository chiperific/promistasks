# frozen_string_literal: true

class AutoTask < ApplicationRecord
  belongs_to :user, inverse_of: :auto_tasks
  validates :title, presence: true

  scope :ordered, -> { order(:position) }
  # Send tasks to the top of the tasklist one at a time in reverse order
  scope :reversed, -> { order(position: :desc) }

  before_create :increment_position

  private

  def increment_position
    self.position = AutoTask.ordered.last.position + 1
  end
end
