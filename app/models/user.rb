# frozen_string_literal: true

class User < ActiveRecord::Base
  include HTTParty
  include Discard::Model

  attr_accessor :register_as

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :recoverable
  devise :database_authenticatable, :registerable,
         :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :jobs, as: :record, class_name: '::Delayed::Job'

  has_many :created_tasks,  class_name: 'Task', inverse_of: :creator, foreign_key: 'creator_id'
  has_many :owned_tasks,    class_name: 'Task', inverse_of: :owner,   foreign_key: 'owner_id'
  has_many :subject_tasks,  class_name: 'Task', inverse_of: :subject, foreign_key: 'subject_id'

  has_many :created_properties, class_name: 'Property', inverse_of: :creator, foreign_key: 'creator_id'
  accepts_nested_attributes_for :created_properties

  has_many :tasklists, inverse_of: :user
  has_many :properties, through: :tasklists
  accepts_nested_attributes_for :tasklists

  has_many :task_users, inverse_of: :user
  has_many :tasks, through: :task_users
  accepts_nested_attributes_for :task_users

  has_many :connections, inverse_of: :user, dependent: :destroy
  has_many :connected_properties, class_name: 'Property', through: :connections
  accepts_nested_attributes_for :connections, allow_destroy: true

  has_many :skill_users, inverse_of: :user, dependent: :destroy
  has_many :skills, through: :skill_users
  accepts_nested_attributes_for :skill_users, allow_destroy: true

  validates :name, :email, uniqueness: true, presence: true
  validates :oauth_id, :oauth_token, uniqueness: true, allow_blank: true
  validates_inclusion_of  :program_staff, :project_staff, :admin_staff,
                          :client, :volunteer, :contractor,
                          :system_admin, in: [true, false]

  validate :must_have_type
  validate :clients_are_singular
  validate :system_admin_must_be_internal, if: -> { system_admin? }

  monetize :rate_cents, allow_nil: true

  after_create :propegate_tasklists, if: -> { oauth_id.present? && discarded_at.blank? }

  # rubocop:disable Layout/IndentationConsistency
  # rubocop:disable Layout/IndentationWidth
  scope :staff,                       -> { undiscarded.where.not(oauth_id: nil) }
  scope :staff_except,                ->(user) { undiscarded.staff.where.not(id: user) }
  scope :not_staff,                   -> { undiscarded.where(oauth_id: nil) }
  scope :with_tasks_for,              ->(property) { created_tasks_for(property).or(owned_tasks_for(property)) }
    scope :created_tasks_for,         ->(property) { undiscarded.where(id: Task.select(:creator_id).where(property: property)) }
    scope :owned_tasks_for,           ->(property) { undiscarded.where(id: Task.select(:owner_id).where(property: property)) }
  scope :without_tasks_for,           ->(property) { without_created_tasks_for(property).without_owned_tasks_for(property) }
    scope :without_created_tasks_for, ->(property) { undiscarded.where.not(id: Task.select(:creator_id).where(property: property)) }
    scope :without_owned_tasks_for,   ->(property) { undiscarded.where.not(id: Task.select(:owner_id).where(property: property)) }
  # rubocop:enable Layout/IndentationConsistency
  # rubocop:enable Layout/IndentationWidth

  def staff?
    program_staff? ||
      project_staff? ||
      admin_staff? ||
      system_admin? ||
      oauth_id.present?
  end

  def oauth?
    oauth_id.present?
  end

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

  def fname
    name.split(' ')[0].capitalize
  end

  def self.from_omniauth(auth)
    @user = where(email: auth.info.email).first_or_create.tap do |user|
      user.name = auth.info.name
      user.password = Devise.friendly_token[0, 20]
      user.oauth_provider = auth.provider
      user.oauth_id = auth.uid
      user.oauth_image_link = auth.info.image
      user.oauth_token = auth.credentials.token
      user.oauth_refresh_token ||= auth.credentials.refresh_token if auth.credentials.refresh_token.present?
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
    end
    @user.save
    @user.reload
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

  # Devise's active needs to be adjusted to account for discarded_at soft-delete
  def active_for_authentication?
    super && !discarded_at
  end

  def refresh_token!
    return false unless token_expired? && oauth_id.present? && oauth_token.present? && oauth_refresh_token.present?
    data = {
      grant_type: 'refresh_token',
      client_id: Rails.application.secrets.google_client_id,
      client_secret: Rails.application.secrets.google_client_secret,
      refresh_token: oauth_refresh_token
    }
    response = HTTParty.post('https://accounts.google.com/o/oauth2/token', { body: data.as_json })
    update(oauth_token: response['access_token'], oauth_expires_at: Time.now.utc + response['expires_in'].to_i.seconds) if response['access_token'].present?
    response
  end

  def token_expired?
    return nil unless oauth_id.present? && oauth_expires_at.present?
    Time.at(oauth_expires_at) < Time.now
  end

  def list_api_tasklists
    return false unless oauth_id.present?
    response = HTTParty.get('https://www.googleapis.com/tasks/v1/users/@me/lists', headers: api_headers)

    return false if response.nil?
    response
  end

  def fetch_default_tasklist
    return false unless oauth_id.present?
    response = HTTParty.get('https://www.googleapis.com/tasks/v1/users/@me/lists/@default', headers: api_headers)

    return false if response.nil?
    response
  end

  private

  def must_have_type
    return true if oauth_id.present? # skip this if it's an oauth user
    if type.empty?
      errors.add(:register_as, 'a user type from the list')
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

  def system_admin_must_be_internal
    errors.add(:system_admin, 'must be internal staff with a linked Google account') unless oauth_id.present?
    true
  end

  def propegate_tasklists
    Property.visible_to(self).each do |property|
      property.ensure_tasklist_exists_for(self)
    end
  end

  def api_headers
    { 'Authorization': 'OAuth ' + oauth_token,
      'Content-type': 'application/json' }
  end
end
