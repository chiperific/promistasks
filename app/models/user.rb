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

  has_many :exclude_property_users, inverse_of: :user, dependent: :destroy
  has_many :excluded_tasklists, class_name: :Property, through: :exclude_property_users, source: :property
  accepts_nested_attributes_for :exclude_property_users, allow_destroy: true

  validates :name, :email, uniqueness: true, presence: true
  validates :oauth_id, :oauth_token, uniqueness: true, allow_blank: true
  validates_inclusion_of  :program_staff, :project_staff, :admin_staff,
                          :client, :volunteer, :contractor,
                          :system_admin, :deus_ex_machina, in: [true, false]

  validate :must_have_type
  validate :clients_are_singular
  before_save :only_one_deus_ex

  monetize :rate_cents, allow_nil: true

  scope :staff, -> { where.not(oauth_id: nil).where(deus_ex_machina: false) }
  scope :not_staff, -> { where(oauth_id: nil).where(deus_ex_machina: false) }
  scope :deus_ex_machina, -> { where(deus_ex_machina: true) }

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
    @user = where(oauth_provider: auth.provider, email: auth.info.email).first_or_create.tap do |user|
      user.name = auth.info.name
      user.password = Devise.friendly_token[0, 20]
      user.oauth_id = auth.uid
      user.oauth_image_link = auth.info.image
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
    end
    @user.update(oauth_token: auth.credentials.token, oauth_refresh_token: auth.credentials.refresh_token)

    @user
  end

  # Devise's RegistrationsController by default calls User.new_with_session
  # before building a resource. This means that, if we need to copy data from session
  # whenever a user is initialized before sign up, we just need to implement
  # new_with_session in our model.
  def self.new_with_session(params, session)
    super.tap do |user|
      if (data = session['devise.google_data']) && session['devise.google_data']['info']
        user.email = data['email'] if user.email.blank?
      end
    end
  end

  def refresh_token
    return false unless token_expired? && oauth_id.present?
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
    return nil unless oauth_id.present?
    Time.at(oauth_expires_at) < Time.now
  end

  def register_as
    # handles grouping of booleans as radial buttons on Devise::registration#new
  end

  def active_for_authentication?
    super && !discarded_at
  end

  def tasklists
    Property.where.not(id: self.excluded_tasklists.select(:property_id))
  end

  private

  def must_have_type
    # skip this if it's an oauth user
    return true if oauth_id.present?
    if type.empty?
      errors.add(:register_as, ': Must have at least one type.')
      false
    else
      true
    end
  end

  def clients_are_singular
    return true unless client?
    errors.add(:register_as, ': Clients can\'t have another type') if type.count > 1
    true
  end

  def only_one_deus_ex
    return true unless deus_ex_machina?

    deus_ex_ary = User.deus_ex_machina
    self.deus_ex_machina = deus_ex_ary.empty? || id == deus_ex_ary.first.id
    true
  end
end
