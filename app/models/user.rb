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
  # accepts_nested_attributes_for :created_properties

  has_many :contractor_payments, class_name: 'Payment', inverse_of: :contractor, foreign_key: 'contractor_id'
  has_many :client_payments,     class_name: 'Payment', inverse_of: :client,     foreign_key: 'client_id'
  has_many :created_payments,    class_name: 'Payment', inverse_of: :creator,    foreign_key: 'creator_id'

  has_many :tasklists, inverse_of: :user, dependent: :destroy
  has_many :properties, through: :tasklists
  accepts_nested_attributes_for :tasklists, allow_destroy: true

  has_many :task_users, inverse_of: :user, dependent: :destroy
  has_many :tasks, through: :task_users
  accepts_nested_attributes_for :task_users, allow_destroy: true

  has_many :connections, inverse_of: :user, dependent: :destroy
  has_many :connected_properties, class_name: 'Property', through: :connections
  accepts_nested_attributes_for :connections, allow_destroy: true

  has_many :skill_users, inverse_of: :user, dependent: :destroy
  has_many :skills, through: :skill_users
  accepts_nested_attributes_for :skill_users, allow_destroy: true

  has_many :park_users, inverse_of: :user, dependent: :destroy
  has_many :parks, through: :park_users
  accepts_nested_attributes_for :park_users, allow_destroy: true

  has_many :organization_billing,     class_name: 'Organization', inverse_of: :billing_contact
  has_many :organization_maintenance, class_name: 'Organization', inverse_of: :maintenance_contact
  has_many :organization_volunteer,   class_name: 'Organization', inverse_of: :volunteer_contact

  validates :name, :email, uniqueness: true, presence: true
  validates :oauth_id, :oauth_token, uniqueness: true, allow_blank: true
  validates_presence_of  :phone, :rate_cents, :adults, :children
  validates_inclusion_of :staff, :client, :volunteer, :contractor,
                         :admin, in: [true, false]
  validate :must_have_type
  validate :clients_are_limited

  monetize :rate_cents, allow_nil: true, allow_blank: true

  before_save :admin_are_staff,      if: -> { admin? && !staff? }
  after_create :propegate_tasklists, if: -> { oauth_id.present? && discarded_at.blank? }
  after_save :discard_connections,   if: -> { discarded_at.present? && discarded_at_before_last_save.nil? }
  after_save :undiscard_connections, if: -> { discarded_at_before_last_save.present? && discarded_at.nil? }

  scope :oauth,                       -> { undiscarded.where.not(oauth_id: nil) }
  scope :staff,                       -> { undiscarded.where.not(oauth_id: nil).or(where(staff: true)).or(where(admin: true)) }
  scope :not_clients,                 -> { undiscarded.where(client: false).or(where(client: true, volunteer: true)) }
  scope :staff_except,                ->(user) { undiscarded.staff.where.not(id: user) }
  scope :not_staff,                   -> { undiscarded.where(oauth_id: nil).where(staff: false) }
  scope :with_tasks_for,              ->(property) { created_tasks_for(property).or(owned_tasks_for(property)) }
    scope :created_tasks_for,         ->(property) { undiscarded.where(id: Task.select(:creator_id).where(property: property)) }
    scope :owned_tasks_for,           ->(property) { undiscarded.where(id: Task.select(:owner_id).where(property: property)) }
  scope :without_tasks_for,           ->(property) { without_created_tasks_for(property).without_owned_tasks_for(property) }
    scope :without_created_tasks_for, ->(property) { undiscarded.where.not(id: Task.select(:creator_id).where(property: property)) }
    scope :without_owned_tasks_for,   ->(property) { undiscarded.where.not(id: Task.select(:owner_id).where(property: property)) }
  scope :created_since,               ->(time) { where('created_at >= ?', time) }
  scope :clients,                     -> { undiscarded.where(client: true) }
  scope :volunteers,                  -> { undiscarded.where(volunteer: true) }
  scope :contractors,                 -> { undiscarded.where(contractor: true) }
  scope :admins,                      -> { undiscarded.where(admin: true) }

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

  def all_tasks
    created_tasks.or(owned_tasks)
  end

  def can_view_park(park)
    return true if admin? || staff?

    return true if created_properties.where(park: park).count.positive?
    return true if all_tasks.joins(:property).where('properties.park_id = ?', park.id).count.positive?

    false
  end

  def fetch_default_tasklist
    return false unless oauth_id.present?

    response = HTTParty.get('https://www.googleapis.com/tasks/v1/users/@me/lists/@default', headers: api_headers)

    return false if response.nil?

    response
  end

  def fname
    name.split(' ')[0].capitalize
  end

  def list_api_tasklists
    return false unless oauth_id.present?

    response = HTTParty.get('https://www.googleapis.com/tasks/v1/users/@me/lists', headers: api_headers)

    return false if response.nil?

    response
  end

  def not_client?
    !client? &&
      (type.present? || admin? || oauth?)
  end

  def not_staff?
    admin? == false &&
      staff? == false
  end

  def oauth?
    oauth_id.present?
  end

  def payments
    client_payments.active + contractor_payments.active
  end

  def refresh_token!
    return false unless token_expired? && oauth_id.present? && oauth_refresh_token.present?

    data = {
      grant_type: 'refresh_token',
      client_id: Rails.application.credentials.google_client_id,
      client_secret: Rails.application.credentials.google_client_secret,
      refresh_token: oauth_refresh_token
    }
    response = HTTParty.post('https://accounts.google.com/o/oauth2/token', { body: data.as_json })

    if response['error']
      update(oauth_token: nil, oauth_expires_at: nil)
    else
      update(oauth_token: response['access_token'], oauth_expires_at: Time.now.utc + response['expires_in'].to_i.seconds) if response['access_token'].present?
    end
    response
  end

  def readable_type
    return 'Staff' if oauth? && type.empty?

    type.join(', ')
  end

  def staff_or_admin?
    admin? || staff?
  end

  def token_expired?
    return true unless oauth_id.present? && oauth_expires_at.present?

    Time.at(oauth_expires_at) < Time.now
  end

  def type
    ary = []
    # TYPES = %w[Staff Client Volunteer Contractor]
    Constant::User::TYPES.each do |i|
      ary << i if send(i.downcase)
    end

    ary << 'Admin' if admin?

    ary
  end

  def write_type(registration)
    self.staff = false
    self.client = false
    self.volunteer = false
    self.contractor = false

    case registration.downcase
    when 'staff'
      self.staff = true
    when 'volunteer'
      self.volunteer = true
    when 'client'
      self.client = true
    when 'contractor'
      self.contractor = true
    else
      errors.add(:register_as, 'a user type from the list')
    end
  end

  private

  def admin_are_staff
    self.staff = true
  end

  def api_headers
    { 'Authorization': 'OAuth ' + oauth_token,
      'Content-type': 'application/json' }
  end

  def clients_are_limited
    return true unless client?
    return true if volunteer?

    errors.add(:register_as, ': Clients can\'t be staff or contractors') if type.count > 1
    true
  end

  def discard_connections
    connections.each(&:discard)
  end

  def must_have_type
    return true if oauth_id.present?

    if type.empty?
      errors.add(:register_as, 'a user type from the list')
      false
    else
      true
    end
  end

  def propegate_tasklists
    Property.visible_to(self).each do |property|
      property.ensure_tasklist_exists_for(self)
    end
  end

  def undiscard_connections
    self.reload
    connections.each(&:undiscard)
  end
end
