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

  def fname
    name.split(' ')[0].capitalize
  end

  def tasks_service
    secrets = Google::APIClient::ClientSecrets.new(
      {
        'web' =>
          {
            'access_token' => oauth_token,
            'refresh_token' => oauth_refresh_token,
            'client_id' => Rails.application.credentials.google_client_id,
            'client_secret' => Rails.application.credentials.google_client_secret
          }
      }
    )
    service = Google::Apis::TasksV1::TasksService.new
    service.authorization = secrets.to_authorization

    service
  end
end
