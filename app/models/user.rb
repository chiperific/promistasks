# frozen_string_literal: true

class User < ApplicationRecord
  include HTTParty
  include Discard::Model

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :created_tasks,  class_name: 'Task', inverse_of: :creator, foreign_key: 'creator_id'
  has_many :owned_tasks,    class_name: 'Task', inverse_of: :owner,   foreign_key: 'owner_id'
  has_many :subject_tasks,  class_name: 'Task', inverse_of: :subject, foreign_key: 'subject_id'

  has_many :connections, inverse_of: :user, dependent: :destroy
  has_many :properties, through: :connections
  accepts_nested_attributes_for :connections, allow_destroy: true

  has_many :skill_users, inverse_of: :user, dependent: :destroy
  has_many :skills, through: :skill_users
  accepts_nested_attributes_for :skill_users, allow_destroy: true

  validates_presence_of :name, :email, unique: true
  validates_inclusion_of  :program_staff, :project_staff, :admin_staff,
                          :client, :volunteer, :contractor,
                          :system_admin, :deus_ex_machina, in: [true, false]

  validate :must_have_type
  before_save :only_one_deus_ex

  monetize :rate_cents, allow_nil: true

  scope :staff, -> { where.not(uid: nil).where(deus_ex_machina: false) }
  scope :not_staff, -> { where(uid: nil).where(deus_ex_machina: false) }
  scope :deus_ex_machina, -> { where(deus_ex_machina: true).first }

  def type
    ary = []

    # INT_TYPES = %w[Program Project Admin].freeze
    Constant::User::INT_TYPES.each do |i|
      sendable = i.downcase + '_staff'
      ary << i + ' Staff' if send(sendable)
    end

    # EXT_TYPES = %w[Client Volunteer Contractor].freeze
    Constant::User::EXT_TYPES.each do |i|
      ary << i if send(i.downcase)
    end

    ary
  end

  def self.from_omniauth(auth)
    @user = where(provider: auth.provider, email: auth.info.email).first_or_create.tap do |user|
      user.name = auth.info.name
      user.uid = auth.uid
      user.password = Devise.friendly_token[0,20]
      user.google_image_link = auth.info.image
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
    end
    @user.update(oauth_token: auth.credentials.token, oauth_refresh_token: auth.credentials.refresh_token)

    @user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session['devise.google_data'] && session['devise.google_data']['info']
        user.email = data['email'] if user.email.blank?
      end
    end
  end

  def refresh_token_if_expired
    return true unless token_expired?
    data = {
      grant_type: 'refresh_token',
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      refresh_token: oauth_refresh_token
    }

    response = HTTParty.post('https://accounts.google.com/o/oauth2/token', { body: data.as_json })
    update(oauth_token: response['access_token'], oauth_expires_at: Time.now.utc + response['expires_in'].to_i.seconds) if response['access_token'].present?
  end

  def token_expired?
    Time.at(oauth_expires_at) < Time.now
  end

  def register_as
    # handles grouping of booleans as radial buttons on Devise::registration#new
  end

  def active_for_authentication?
    super && !discarded_at
  end

  private

  def must_have_type
    if type.empty?
      errors.add(:register_as, ': Must have at least one type.')
      false
    else
      true
    end
  end

  def only_one_deus_ex
    return true unless deus_ex_machina?
    self.deus_ex_machina = User.deus_ex_machina.empty?
    true
  end
end
