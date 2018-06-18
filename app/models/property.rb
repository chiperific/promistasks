# frozen_string_literal: true

class Property < ApplicationRecord
  include Discard::Model

  has_many :connections, inverse_of: :property, dependent: :destroy
  has_many :users, through: :connections
  accepts_nested_attributes_for :connections, allow_destroy: true

  belongs_to :creator, class_name: 'User', inverse_of: :created_properties
  has_many :tasklists, inverse_of: :property, dependent: :destroy

  has_many :tasks, inverse_of: :property, dependent: :destroy

  validates :name, :address, uniqueness: true, presence: true
  validates_presence_of :creator_id
  validates_uniqueness_of :certificate_number, :serial_number, allow_nil: true
  validates_inclusion_of :is_private, :is_default, :created_from_api, in: [true, false]

  monetize :cost_cents, :lot_rent_cents, :budget_cents, allow_nil: true

  before_validation :name_and_address,              if: :unsynced_name_address?
  before_validation :only_one_default,              if: -> { is_default? }
  before_validation :default_must_be_private,       if: -> { discarded_at.nil? && is_default? && !is_private? }
  before_validation :refuse_to_discard_default,     if: -> { discarded_at.present? && is_default? }
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
  # there can be only one, highlander, regardless of user
  # scope :default_for,    ->(user) { created_by(user).where(is_default: true) }

  class << self
    alias archived discarded
    alias active kept
  end

  def full_address
    addr = address
    addr += ', ' + city unless city.blank?
    addr += ', ' + state unless city.blank?
    addr += ', ' + postal_code unless postal_code.blank?
    addr
  end

  def budget_remaining
    self.budget ||= default_budget
    self.budget - tasks.map(&:cost).sum
  end

  def ensure_tasklist_exists_for(user)
    return false if user.oauth_id.nil?
    tasklist = tasklists.where(user: user).first_or_initialize
    return tasklist unless tasklist.new_record? || tasklist.google_id.nil?
    tasklist.save
    tasklist.reload
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

  def only_one_default
    return true if Property.where(is_default: true).count == 0
    self.is_default = false
  end

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
end
