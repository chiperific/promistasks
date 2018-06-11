# frozen_string_literal: true

class Tasklist < ApplicationRecord
  include HTTParty

  belongs_to :user,     inverse_of: :tasklists
  belongs_to :property, inverse_of: :tasklists

  validates :property, presence: true, uniqueness: { scope: :user }
  validates_uniqueness_of :google_id, allow_nil: true

  before_validation :sequence_google_id, if: -> { Rails.env.test? }

  def list_api_tasks
    return false unless user.oauth_id.present?
    user.refresh_token!
    HTTParty.get('https://www.googleapis.com/tasks/v1/lists/' + google_id + '/tasks/', headers: headers.as_json)
  end

  private

  def sequence_google_id
    return true if property&.name == 'validate'
    number = Tasklist.count.positive? ? Tasklist.last.id + 1 : 1
    self.google_id += number.to_s unless google_id.nil?
  end

  def api_headers
    { 'Authorization': 'OAuth ' + user.oauth_token,
      'Content-type': 'application/json' }
  end
end
