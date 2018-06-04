# frozen_string_literal: true

class Tasklist < ApplicationRecord
  belongs_to :user,     inverse_of: :tasklists
  belongs_to :property, inverse_of: :tasklists

  validates :property, presence: true, uniqueness: { scope: :user }
  validates_uniqueness_of :google_id, allow_nil: true
end
