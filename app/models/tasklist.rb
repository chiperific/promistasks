# frozen_string_literal: true

class Tasklist < ApplicationRecord
  belongs_to :user,     inverse_of: :tasklists

  validates_presence_of :title, :google_id
  validates_uniqueness_of :google_id

  scope :alphabetical, -> { order(:title) }

  def push_auto_task!(task)
    user.tasks_service.insert_task(
      google_id,
      task.as_google_object,
      options: {
        authorization: user.authorization
      }
    )
  end

  def push_auto_tasks!
    AutoTask.reversed.each do |task|
      push_auto_task!(task)
    end

    update(auto_tasks_created: true)
  end
end
