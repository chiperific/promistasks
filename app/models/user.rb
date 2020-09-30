# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :auto_tasks, inverse_of: :user
  has_many :tasklists, inverse_of: :user, dependent: :destroy

  validates :oauth_id, :oauth_token, uniqueness: true, allow_blank: true

  def self.from_omniauth(auth)
    @user = where(email: auth.info.email).first_or_initialize.tap do |user|
      user.name = auth.info.name
      user.oauth_provider = auth.provider
      user.oauth_id = auth.uid
      user.oauth_image_link = auth.info.image
      user.oauth_token = auth.credentials.token
      user.oauth_refresh_token ||= auth.credentials.refresh_token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
    end

    @user.save
    @user.reload
  end

  def authorization
    Google::APIClient::ClientSecrets.new(
      {
        'web' =>
          {
            'access_token' => oauth_token,
            'refresh_token' => oauth_refresh_token,
            'client_id' => Rails.application.credentials.google_client_id,
            'client_secret' => Rails.application.credentials.google_client_secret
          }
      }
    ).to_authorization
  end

  def fname
    name.split(' ')[0].capitalize
  end

  def oauth_expired?
    oauth_expires_at < Time.now
  end

  def tasks_service
    service = Google::Apis::TasksV1::TasksService.new
    service.authorization = authorization

    if oauth_expired?
      response = service.authorization.refresh!
      new_expiry = Time.now + response['expires_in']
      update_column(:oauth_expires_at, new_expiry)
    end

    service
  end

  def check_tasklists
    tasks_service.list_tasklists(fields: 'items(id,title)')
  end

  def import_tasklists!
    response = tasks_service.list_tasklists(fields: 'items(id,title)')

    response.items.each do |item|
      next if item.title == 'Primary'

      Tasklist.where(google_id: item.id, user: self).first_or_initialize.tap do |tl|
        tl.title = item.title
        tl.save
      end
    end
  end

  private
end
