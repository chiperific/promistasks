# frozen_string_literal: true

class AutoTask < ApplicationRecord
  belongs_to :user, inverse_of: :auto_tasks
  validates :title, presence: true

  validates :position, uniqueness: true, if: -> { position.present? }

  scope :ordered, -> { order(:position) }
  # Send tasks to the top of the tasklist one at a time in reverse order
  scope :reversed, -> { order(position: :desc) }

  before_create :increment_position

  def as_google_object
    Google::Apis::TasksV1::Task.new(title: title, notes: notes, due: due)
  end

  def due
    return nil if days_until_due.zero?

    (DateTime.now + days_until_due.days).rfc3339
  end

  def self.reposition(positions)
    AutoTask.update_all(position: nil)

    positions.each_with_index do |id, i|
      AutoTask.find(id.to_i).update_columns(position: i)
    end
  end

  private

  def increment_position
    last = AutoTask.ordered.last&.position || 0
    self.position = last + 1
  end
end
