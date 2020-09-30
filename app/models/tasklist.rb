# frozen_string_literal: true

class Tasklist < ApplicationRecord
  belongs_to :user,     inverse_of: :tasklists

  validates_presence_of :title, :google_id
  validates_uniqueness_of :google_id

  scope :alphabetical, -> { order(:title) }
  scope :unsynced, -> { where(auto_tasks_created: false) }

  def active_on_google?
    response = user.tasks_service.get_tasklist(google_id, fields: 'id')
    response.present?
  rescue Google::Apis::ClientError => e
    return false if e.message == "invalid: Invalid task list ID"
  end

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
    return unless active_on_google?

    user.auto_tasks.reversed.each do |task|
      push_auto_task!(task)
    end

    update(auto_tasks_created: true)
  end
end
