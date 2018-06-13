# frozen_string_literal: true

class Property < ApplicationRecord
  include Discard::Model

  has_many :connections, inverse_of: :property, dependent: :destroy
  has_many :users, through: :connections
  accepts_nested_attributes_for :connections, allow_destroy: true

  belongs_to :creator, class_name: 'User', inverse_of: :created_properties
  has_many :tasklists, inverse_of: :property, dependent: :destroy

  has_many :tasks, inverse_of: :property, dependent: :destroy

  validates_presence_of :creator_id
  validates :name, :address, uniqueness: true, presence: true
  validates_uniqueness_of :certificate_number, :serial_number, allow_nil: true
  validates_inclusion_of :is_private, in: [true, false]

  monetize :cost_cents, :lot_rent_cents, :budget_cents, allow_nil: true

  before_validation :name_and_address, if: :unsynced_name_address?
  before_save :default_budget

  after_create :create_tasklists,                unless: -> { discarded_at.present? }
  after_update :cascade_by_privacy,                 if: -> { saved_change_to_is_private? }
  after_update :discard_tasks_and_delete_tasklists, if: -> { discarded_at.present? }
  after_update :update_tasklists,               unless: -> { discarded_at.present? }

  scope :needs_title,    ->       { undiscarded.where(certificate_number: nil) }
  scope :public_visible, ->       { undiscarded.where(is_private: false) }
  scope :created_by,     ->(user) { undiscarded.where(creator: user) }
  scope :with_tasks_for, ->(user) { undiscarded.where(id: Task.select(:property_id).where('tasks.creator_id = ? OR tasks.owner_id = ?', user.id, user.id)) }
  scope :related_to,     ->(user) { created_by(user).or(with_tasks_for(user)) }
  scope :visible_to,     ->(user) { related_to(user).or(public_visible) }

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

  def default_budget
    self.budget = Money.new(7_500_00) if budget.blank?
  end

  def ensure_tasklist_exists_for(user)
    tasklist = tasklists.where(user: user).first_or_initialize
    return tasklist unless tasklist.new_record?
    tasklist.save
    tasklist.reload
  end

  private

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
      User.staff_except(creator).each do |user|
        tasklist = tasklists.where(user: creator).first_or_initialize
        next if tasklist.new_record?
        tasklist.destroy
        # this feels like the wrong place for this
        # maybe trigger on task#after_update, if: -> { discarded_at.present }
        # but update_all skips callbacks
        tasks.task_users.where(user: user).destroy_all
        tasks.where(owner: user).update_all(discarded_at: discarded_at)
      end
    else # became public
      User.staff_except(creator).each do |user|
        tasklist = tasklists.where(user: user).first_or_initialize
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
    tasks.task_users.destroy_all if tasks.exists? && tasks.task_users.exists?
    tasks.update_all(discarded_at: discarded_at)
  end

  def update_tasklists
    return true unless saved_change_to_name?

    if is_private?
      tasklist = tasklists.where(user: creator).first_or_create
      action = tasklist.google_id.present? ? :update : :insert
      response = TasklistClient.new.send(action, creator, tasklist)
      tasklist.google_id = response['id']
      tasklist.save
    else
      User.staff.each do |user|
        tasklist = tasklists.where(user: user).first_or_create
        action = tasklist.google_id.present? ? :update : :insert
        response = TasklistClient.new.send(action, user, tasklist)
        tasklist.google_id = response['id']
        tasklist.save
      end
    end
  end

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

  # def delete_with_api
  #   return true if discarded_at.blank?

  #   if is_private?
  #     tasklist = tasklists.where(user: creator).first
  #     TasklistClient.new.delete(creator, tasklist)
  #     tasklist.destroy! unless tasklist.new_record?
  #   else
  #     User.staff.each do |user|
  #       tasklist = tasklists.where(user: user).first
  #       TasklistClient.new.delete(user, tasklist)
  #       tasklist.destroy! unless tasklist.new_record?
  #     end
  #   end

  #   discard_tasks!
  # end

  # def propagate_to_api_by_privacy
  #   if is_private? # became private
  #     User.staff_except(creator).each do |user|
  #       tasklist = tasklists.where(user: user).first_or_initialize
  #       TasklistClient.new.delete(user, tasklist) unless tasklist.new_record?
  #       tasklist.destroy
  #       tasks.task_users.where(user: user).destroy_all if tasks.exists? && tasks.task_users.exists?
  #     end
  #   else # became public
  #     User.staff_except(creator).each do |user|
  #       tasklist = tasklists.where(user: user).first_or_initialize
  #       action = tasklist.new_record? ? :insert : :update
  #       response = TasklistClient.new.send(action, user, tasklist)
  #       tasklist.google_id = response['id']
  #       tasklist.save
  #     end
  #   end
  # end

  # def discard_tasks!
  #   tasks.each do |task|
  #     task.update(discarded_at: discarded_at)
  #   end
  # end
end
