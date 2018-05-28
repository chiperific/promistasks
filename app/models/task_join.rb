class TaskJoin < ApplicationRecord
  belongs_to :user, inverse_of: :task_joins
  belongs_to :task, inverse_of: :task_joins

  validates :user, :property, presence: true, uniqueness: true
  validates_uniqueness_of :google_id, allow_nil: true

  before_save :copy_position_as_integer, if: -> { position.present? }

  private

  def copy_position_as_integer
    self.position_int = position.to_i
  end
end
