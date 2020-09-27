# frozen_string_literal: true

class Tasklist < ApplicationRecord
  belongs_to :user,     inverse_of: :tasklists

  validates_presence_of :title, :google_id
  validates_uniqueness_of :google_id

  scope :alphabetical, -> { order(:title) }
end
