# frozen_string_literal: true

class Property < ApplicationRecord
  include Discard::Model

  has_many :tasklists, inverse_of: :property, dependent: :destroy
  has_many :users, through: :tasklists
  accepts_nested_attributes_for :tasklists

  has_many :connections, inverse_of: :property, dependent: :destroy
  has_many :connected_users, class_name: 'User', through: :connections
  accepts_nested_attributes_for :connections, allow_destroy: true

  has_many :tasks, inverse_of: :property, dependent: :destroy
  has_many :payments, inverse_of: :property, dependent: :destroy
  has_many :utilities, through: :payments

  belongs_to :creator, class_name: 'User', inverse_of: :created_properties
  belongs_to :park, inverse_of: :properties, required: false

  validates :name, uniqueness: true, presence: true
  validates_presence_of :creator_id
  validates_uniqueness_of :address, :certificate_number, :serial_number, allow_nil: true, allow_blank: true
  validates_inclusion_of :is_private, :is_default, :ignore_budget_warning, :created_from_api, :show_on_reports, in: [true, false]
  validates :stage, presence: true, inclusion: { in: Constant::Property::STAGES, message: "must be one of these: #{Constant::Property::STAGES.to_sentence}" }

  monetize :cost_cents, :lot_rent_cents, :budget_cents, :additional_cost_cents, allow_nil: true

  geocoded_by :full_address

  before_validation :address_required,              unless: -> { is_default? || created_from_api? }
  before_validation :use_address_for_name,          if: -> { name.blank? }
  before_validation :default_must_be_private,       if: -> { discarded_at.nil? && is_default? && !is_private? }
  before_validation :refuse_to_discard_default,     if: -> { discarded_at.present? && is_default? }
  before_validation :refuse_to_discard_hastily,     if: -> { discarded_at.present? }
  after_validation :geocode,                        if: -> { address_has_changed? && !is_default? }
  before_save  :default_budget,                     if: -> { budget.blank? }
  after_create :create_tasklists,                   unless: -> { discarded_at.present? || created_from_api? }
  after_create :create_default_tasks,               unless: -> { discarded_at.present? || is_default? }
  after_update :cascade_by_privacy,                 if: -> { saved_change_to_is_private? }
  after_update :discard_tasks_and_delete_tasklists, if: -> { discarded_at.present? && errors.empty? }
  after_update :update_tasklists,                   if: -> { discarded_at.nil? && saved_change_to_name? }
  after_save :discard_relations,                    if: -> { discarded_at.present? && discarded_at_before_last_save.blank? }
  after_save :undiscard_relations,                  if: -> { discarded_at_before_last_save.present? && discarded_at.blank? }

  scope :except_default, ->       { where(is_default: false) }
  scope :needs_title,    ->       { except_default.undiscarded.where(certificate_number: nil) }
  scope :public_visible, ->       { except_default.undiscarded.where(is_private: false) }
  scope :created_by,     ->(user) { except_default.undiscarded.where(creator: user) }
  scope :with_tasks_for, ->(user) { except_default.undiscarded.where(id: Task.select(:property_id).where('tasks.creator_id = ? OR tasks.owner_id = ?', user.id, user.id)) }
  scope :related_to,     ->(user) { except_default.created_by(user).or(with_tasks_for(user)) }
  scope :visible_to,     ->(user) { related_to(user).or(public_visible) }
  scope :over_budget,    ->       { except_default.where(ignore_budget_warning: false).joins(:tasks).group(:id).having('sum(tasks.cost_cents) > properties.budget_cents') }
  scope :nearing_budget, ->       { except_default.where(ignore_budget_warning: false).joins(:tasks).group(:id).having('sum(tasks.cost_cents) > properties.budget_cents - 50000 AND sum(tasks.cost_cents) < properties.budget_cents') }
  scope :created_since,  ->(time) { except_default.where('created_at >= ?', time) }
  scope :reportable,     ->       { except_default.where(show_on_reports: true) }

  class << self
    alias archived discarded
    alias active kept
  end

  # fake scopes for Property#list ajax-ing
  def self.approved
    ary = []
    Property.except_default.each do |property|
      next if property.discarded?

      ary << property if property.occupancy_status == 'approved applicant'
    end
    ary
  end

  def self.complete
    ary = []
    Property.except_default.each do |property|
      ary << property if property.occupancy_status == 'complete'
    end
    ary
  end

  def self.occupied
    ary = []
    Property.except_default.each do |property|
      next if property.discarded?

      ary << property if property.occupancy_status == 'occupied'
    end
    ary
  end

  def self.pending
    ary = []
    Property.except_default.each do |property|
      next if property.discarded?

      ary << property if property.occupancy_status == 'pending application'
    end
    ary
  end

  def self.vacant
    ary = []
    Property.except_default.each do |property|
      next if property.discarded?

      ary << property if property.occupancy_status == 'vacant'
    end
    ary
  end
  # end fake scopes

  def address_has_changed?
    return false if address.blank?

    address_changed? ||
      city_changed? ||
      state_changed? ||
      postal_code_changed?
  end

  def budget_remaining
    self.budget ||= default_budget
    self.budget - cost_to_date
  end

  def completion_date
    return actual_completion_date if actual_completion_date.present?
    return expected_completion_date if expected_completion_date.present? && expected_completion_date.future?

    'not set'
  end

  def cost_to_date
    sum = cost_cents.to_i + additional_cost_cents.to_i
    sum += tasks.has_cost.map { |t| t.cost_cents || 0 }.sum
    sum += payments.paid.map { |p| p.payment_amt_cents || 0 }.sum

    Money.new(sum)
  end

  def ensure_tasklist_exists_for(user)
    return false if user.oauth_id.nil?

    tasklist = tasklists.where(user: user).first_or_initialize
    return tasklist unless tasklist.new_record? || tasklist.google_id.nil?

    tasklist.save
    tasklist.reload
  end

  def full_address
    addr = address
    addr += ', ' + city unless city.blank?
    addr += ', ' + state unless city.blank?
    addr += ', ' + postal_code unless postal_code.blank?
    addr
  end

  def good_address?
    address.present? && city.present? && state.present?
  end

  def google_map
    return 'no_property.jpg' unless good_address?

    center = [latitude, longitude].join(',')
    key = Rails.application.credentials.google_maps_api_key
    "https://maps.googleapis.com/maps/api/staticmap?key=#{key}&size=355x266&zoom=17&markers=color:red%7C#{center}"
  end

  def google_map_link
    return false unless good_address?

    base = 'https://www.google.com/maps/?q='
    base + full_address.tr(' ', '+')
  end

  def needs_title?
    certificate_number.blank? || certificate_number.nil?
  end

  def occupancies
    connections.where(relationship: 'tennant').order(:stage_date)
  end

  def occupancy_status
    return 'vacant' if occupancies.empty?

    case occupancies.last.stage
    when 'approved'
      status = 'approved applicant'
    when 'transferred title'
      status = 'complete'
    when 'applied'
      status = 'pending application'
    when 'vacated'
      status = 'vacant'
    when 'returned property'
      status = 'vacant'
    else # 'moved in', 'initial walkthrough', 'final walkthrough'
      status = 'occupied'
    end

    status
  end

  def occupancy_details
    occupancies = connections.where(relationship: 'tennant').order(:stage_date)
    return 'Vacant' if occupancies.empty?

    if ['vacated', 'returned property'].include? occupancies.last.stage
      details = 'Vacant'
    else
      details = occupancies.last.user.name + ' ' +
                occupancies.last.stage + ' on ' +
                occupancies.last.stage_date.strftime('%b %-d, %Y')
    end
    details
  end

  def over_budget?
    budget_remaining.negative? && !ignore_budget_warning
  end

  def rent_to_date
    Money.new payments.paid.only_rent.map { |p| p.payment_amt_cents || 0 }.sum
  end

  def utilities_to_date
    Money.new payments.paid.only_utilities.map { |p| p.payment_amt_cents || 0 }.sum
  end

  def update_tasklists
    # since tasklist is only { property, user, google_id }, changing other details about the property won't trigger an api call from tasklist
    # however, if the user changes, then a new tasklist will be created, which triggers the #api_create on after_create callback
    if is_private?
      tasklist = ensure_tasklist_exists_for(creator)
      tasklist.api_update
    else
      User.staff.each do |user|
        tasklist = ensure_tasklist_exists_for(user)
        tasklist.api_update unless tasklist == false
      end
    end
  end

  def utilities_list
    return 'none' unless utilities.any?

    utilities.select(&:name).uniq
  end

  def visible_to?(user)
    creator == user ||
      tasks.related_to(user).present? ||
      !is_private?
  end

  private

  def address_required
    return true unless address.blank?

    errors.add(:address, 'can\'t be blank')
  end

  def cascade_by_privacy
    if is_private? # became private
      # Only remove the tasklist from users without related tasks
      User.without_tasks_for(self).each do |user|
        tasklist = tasklists.where(user: user).first_or_initialize
        next if tasklist.new_record?

        tasklist.destroy
      end

    else # became public
      User.staff_except(creator).each do |user|
        tasklist = ensure_tasklist_exists_for(user)
        next unless tasklist.new_record? || tasklist.google_id.nil?

        tasklist.api_insert
      end
    end
  end

  def create_tasklists
    if is_private?
      ensure_tasklist_exists_for(creator)
    else
      User.staff.each do |user|
        ensure_tasklist_exists_for(user)
      end
    end
  end

  def create_default_tasks
    tasks.new.tap do |task|
      task.title = 'Get the title for ' + name
      task.creator = creator
      task.owner = creator
      task.save
    end

    tasks.new.tap do |task|
      task.title = 'Set up utilities for ' + name
      task.creator = creator
      task.owner = creator
      task.save
    end

    inspection_owner = Organization.first.maintenance_contact.present? ? Organization.first.maintenance_contact : creator

    tasks.new.tap do |task|
      task.title = 'Perform an inspection at ' + name
      task.creator = creator
      task.owner = inspection_owner
      task.save
    end
  end

  def default_budget
    self.budget = Money.new(7_500_00)
  end

  def default_must_be_private
    self.is_private = true
    self.show_on_reports = false
  end

  def discard_relations
    connections.discard_all
    payments.discard_all
  end

  def discard_tasks_and_delete_tasklists
    Tasklist.where(property: self).destroy_all
    Task.where(property: self).discard_all
  end

  def refuse_to_discard_default
    self.discarded_at = nil
  end

  def refuse_to_discard_hastily
    errors.add(:archive, "failed because #{tasks.in_process.size} active tasks exist") if tasks.in_process.any?
    errors.add(:archive, "failed because #{payments.not_paid.size} active payments exist") if payments.not_paid.any?

    return false if tasks.in_process.any? || payments.not_paid.any?

    true
  end

  def undiscard_relations
    self.reload
    connections.undiscard_all
    tasks.undiscard_all
    payments.undiscard_all
  end

  def use_address_for_name
    self.name = address
  end
end
