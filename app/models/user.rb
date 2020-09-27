# frozen_string_literal: true

class User < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :recoverable,
  # :database_authenticatable, :registerable, :rememberable, :trackable,
  # :validatable,
  # devise :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :auto_tasks, inverse_of: :user
  has_many :tasklists, inverse_of: :user, dependent: :destroy

  validates :oauth_id, :oauth_token, uniqueness: true, allow_blank: true


  def self.from_omniauth(auth)
    @user = where(email: auth.info.email).first_or_create.tap do |user|
      user.name = auth.info.name
      user.password = Devise.friendly_token[0, 20]
      user.oauth_provider = auth.provider
      user.oauth_id = auth.uid
      user.oauth_image_link = auth.info.image
      user.oauth_token = auth.credentials.token
      user.oauth_refresh_token ||= auth.credentials.refresh_token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.staff = true
      user.phone = Organization.first.default_phone
    end
    @user.save
    @user.reload
  end

  # Devise's RegistrationsController by default calls User.new_with_session
  # before building a resource. This means that, if we need to copy data from session
  # whenever a user is initialized before sign up, we just need to implement
  # new_with_session in our model.
  # def self.new_with_session(params, session)
  #   super.tap do |user|
  #     if (data = session['devise.google_data']) && session['devise.google_data']['info']
  #       user.email = data['email'] if user.email.blank?
  #     end
  #   end
  # end
end
