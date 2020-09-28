# frozen_string_literal: true

class Tasklist < ApplicationRecord
  belongs_to :user,     inverse_of: :tasklists

  validates_presence_of :title, :google_id
  validates_uniqueness_of :google_id

  scope :alphabetical, -> { order(:title) }

  def self.import_for(user)
    response = user.tasks_service.list_tasklists(fields: 'items(id,title)')

    response.items.each do |item|
      next if item.title == 'Primary'

      where(google_id: item.id).first_or_initialize.tap do |tl|
        tl.title = item.title
        tl.user = user
        tl.save
      end
    end
  end
end
