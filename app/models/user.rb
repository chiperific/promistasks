# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  scope :staff, -> { where.not(uid: nil) }
  scope :not_staff, -> { where(uid: nil) }

  def self.from_omniauth(auth)
    @user = where(provider: auth.provider, email: auth.info.email ).first_or_create.tap do |user|
      user.name = auth.info.name
      user.uid = auth.uid
      user.password = Devise.friendly_token[0,20]
      user.google_image_link = auth.info.image
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.oauth_login = true
    end

    @user.update( oauth_token: auth.credentials.token, oauth_login: true, system_login: false )

    @user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session['devise.google_data'] && session['devise.google_data']['info']
        user.email = data['email'] if user.email.blank?
      end
    end
  end
end
