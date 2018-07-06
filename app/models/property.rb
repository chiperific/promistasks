# frozen_string_literal: true

class Property < ApplicationRecord
  include Discard::Model

  has_many :tasklists, inverse_of: :property, dependent: :destroy
  has_many :users, through: :tasklists
  accepts_nested_attributes_for :tasklists

  has_many :tasks, inverse_of: :property, dependent: :destroy

  belongs_to :creator, class_name: 'User', inverse_of: :created_properties

  has_many :connections, inverse_of: :property, dependent: :destroy
  has_many :connected_users, class_name: 'User', through: :connections
  accepts_nested_attributes_for :connections, allow_destroy: true

  validates :name, :address, uniqueness: true, presence: true
  validates_presence_of :creator_id
  validates_uniqueness_of :certificate_number, :serial_number, allow_nil: true, allow_blank: true
  validates_inclusion_of :is_private, :is_default, :ignore_budget_warning, :created_from_api, in: [true, false]

  monetize :cost_cents, :lot_rent_cents, :budget_cents, allow_nil: true

  geocoded_by :full_address

  before_validation :name_and_address,              if: :unsynced_name_address?
  # before_validation :only_one_default,              if: -> { is_default? }
  before_validation :default_must_be_private,       if: -> { discarded_at.nil? && is_default? && !is_private? }
  before_validation :refuse_to_discard_default,     if: -> { discarded_at.present? && is_default? }
  after_validation :geocode,                        if: -> { address_has_changed? && !is_default? }
  before_save  :default_budget,                     if: -> { budget.blank? }
  after_create :create_tasklists,                   unless: -> { discarded_at.present? || created_from_api? }
  after_update :cascade_by_privacy,                 if: -> { saved_change_to_is_private? }
  after_update :discard_tasks_and_delete_tasklists, if: -> { discarded_at.present? }
  after_update :update_tasklists,                   if: -> { discarded_at.nil? && saved_change_to_name? }

  scope :needs_title,    ->       { undiscarded.where(certificate_number: nil) }
  scope :public_visible, ->       { undiscarded.where(is_private: false) }
  scope :created_by,     ->(user) { undiscarded.where(creator: user) }
  scope :with_tasks_for, ->(user) { undiscarded.where(id: Task.select(:property_id).where('tasks.creator_id = ? OR tasks.owner_id = ?', user.id, user.id)) }
  scope :related_to,     ->(user) { created_by(user).or(with_tasks_for(user)) }
  scope :visible_to,     ->(user) { related_to(user).or(public_visible) }
  scope :over_budget,    ->       { where(ignore_budget_warning: false).joins(:tasks).group(:id).having('sum(tasks.cost_cents) > properties.budget_cents') }
  scope :nearing_budget, ->       { where(ignore_budget_warning: false).joins(:tasks).group(:id).having('sum(tasks.cost_cents) > properties.budget_cents - 50000 AND sum(tasks.cost_cents) < properties.budget_cents') }

  class << self
    alias archived discarded
    alias active kept
  end

  def good_address?
    address.present? && city.present? && state.present?
  end

  def full_address
    addr = address
    addr += ', ' + city unless city.blank?
    addr += ', ' + state unless city.blank?
    addr += ', ' + postal_code unless postal_code.blank?
    addr
  end

  def google_map
    return 'no_property.jpg' unless good_address?
    center = [latitude, longitude].join(',')
    key = Rails.application.secrets.google_maps_api_key
    "https://maps.googleapis.com/maps/api/staticmap?key=#{key}&center=#{center}&size=355x266&zoom=17"
  end

  def google_street_view
    return 'no_property.jpg' unless good_address?
    center = [latitude, longitude].join(',')
    key = Rails.application.secrets.google_maps_api_key
    "https://maps.googleapis.com/maps/api/streetview?key=#{key}&location=#{center}&size=355x266"
  end

  def address_has_changed?
    address_changed? ||
      city_changed? ||
      state_changed? ||
      postal_code_changed?
  end

  def budget_remaining
    self.budget ||= default_budget
    task_ary = tasks.map(&:cost)
    task_ary.map! { |b| b || 0 }
    self.budget - task_ary.sum
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
        tasklist.api_update
      end
    end
  end

  def ensure_tasklist_exists_for(user)
    return false if user.oauth_id.nil?
    tasklist = tasklists.where(user: user).first_or_initialize
    return tasklist unless tasklist.new_record? || tasklist.google_id.nil?
    tasklist.save
    tasklist.reload
  end

  def can_be_viewed_by(user)
    creator == user ||
      tasks.where('creator_id = ? OR owner_id = ?', user.id, user.id).present? ||
      !is_private?
  end

  private

  def unsynced_name_address?
    return false if name.present? && address.present?
    return false if name.blank? && address.blank?
    true
  end

  def name_and_address
    self.address ||= name
    self.name ||= address
    true
  end

  def default_budget
    self.budget = Money.new(7_500_00)
  end

  # def only_one_default
  #   return true if Property.where(is_default: true).count == 0
  #   return true if Property.where(is_default: true).count == 1 && self == Property.where(is_default: true).first
  #   self.is_default = false
  # end

  def default_must_be_private
    self.is_private = true
  end

  def refuse_to_discard_default
    self.discarded_at = nil
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

  def discard_tasks_and_delete_tasklists
    Tasklist.where(property: self).each do |tasklist|
      tasklist.api_delete
      tasklist.destroy
    end
    # this feels like the wrong place for this
    # maybe trigger on task#after_update, if: -> { discarded_at.present }
    # but update_all skips callbacks
    tasks.each do |task|
      task.task_users.destroy_all if task.present? && task.task_users.present?
    end
    tasks.update_all(discarded_at: discarded_at)
  end
end
