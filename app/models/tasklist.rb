# frozen_string_literal: true

class Tasklist < ApplicationRecord
  include HTTParty
  BASE_URI = 'https://www.googleapis.com/tasks/v1/users/@me/lists'

  belongs_to :user,     inverse_of: :tasklists
  belongs_to :property, inverse_of: :tasklists

  validates :property, presence: true, uniqueness: { scope: :user }
  validates_uniqueness_of :google_id, allow_nil: true

  before_destroy :api_delete
  after_create   :api_insert, unless: -> { google_id.present? }

  def list_api_tasks
    return false unless user.oauth_id.present?
    user.refresh_token!
    response = HTTParty.get('https://www.googleapis.com/tasks/v1/lists/' + google_id + '/tasks/', headers: api_headers)

    response['id'] = sequence_google_id(response['id']) if Rails.env.test?

    update_columns(google_id: response['id'], updated_at: response['updated'])

    response
  end

  def api_get
    return false unless user.oauth_id.present? && google_id.present?
    user.refresh_token!
    HTTParty.get(BASE_URI + '/' + google_id, headers: api_headers)
  end

  def api_insert
    return false if user.oauth_id.nil? || property.created_from_api?
    user.refresh_token!
    body = { title: property.name }.to_json
    response = HTTParty.post(BASE_URI, { headers: api_headers, body: body })

    response['id'] = sequence_google_id(response['id']) if Rails.env.test?

    update_columns(google_id: response['id'], updated_at: response['updated'])
    response
  end

  def api_update
    return false unless user.oauth_id.present? && google_id.present?
    user.refresh_token!
    body = { title: property.name }.to_json
    response = HTTParty.patch(BASE_URI + '/' + google_id, { headers: api_headers, body: body })
    update_columns(updated_at: response['updated'])
    response
  end

  def api_delete
    return false unless user.oauth_id.present? && google_id.present?
    user.refresh_token!
    HTTParty.delete(BASE_URI + '/' + google_id, headers: api_headers)
  end

  private

  def sequence_google_id(response_id)
    return response_id if property&.name == 'validate'
    number = Tasklist.count.positive? ? Tasklist.last.id + 1 : 1
    response_id + number.to_s + Random.rand(0...3000).to_s
  end

  def api_headers
    { 'Authorization': 'OAuth ' + user.oauth_token,
      'Content-type': 'application/json' }.as_json
  end
end
