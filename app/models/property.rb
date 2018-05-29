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
  validates_inclusion_of :private, in: [true, false]

  monetize :cost_cents, :lot_rent_cents, :budget_cents, allow_nil: true

  before_validation :name_and_address, if: :unsynced_name_address?
  before_save  :default_budget
  after_create :create_with_api, if: :not_discarded?
  after_update :update_with_api
  after_update :propagate_to_api_by_privacy, if: -> { saved_change_to_private? }
  after_update :delete_with_api, if: -> { discarded_at.present? }

  scope :needs_title, -> { undiscarded.where(certificate_number: nil) }
  scope :public_visible, -> { undiscarded.where(private: false) }

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

  private

  def not_discarded?
    discarded_at.blank?
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

  def create_with_api
    if private?
      tasklist = tasklists.where(user: creator).first_or_create
      response = TasklistClient.new.insert(creator, tasklist)
      tasklist.update(google_id: response['id'])
    else
      User.staff.each do |user|
        tasklist = tasklists.where(user: user).first_or_create
        response = TasklistClient.new.insert(user, tasklist)
        tasklist.update(google_id: response['id'])
      end
    end
  end

  def update_with_api
    return true unless saved_change_to_name?

    if private?
      tasklist = tasklists.where(user: creator).first_or_create
      action = tasklist.google_id.present? ? :update : :insert
      response = TasklistClient.new.send(action, creator, tasklist)
      tasklist.update(google_id: response['id'])
    else
      User.staff.each do |user|
        tasklist = tasklists.where(user: user).first_or_create
        action = tasklist.google_id.present? ? :update : :insert
        response = TasklistClient.new.send(action, user, tasklist)
        tasklist.update(google_id: response['id'])
      end
    end
  end

  def delete_with_api
    return true if discarded_at.blank?

    if private?
      tasklist = tasklists.where(user: creator).first_or_create
      TasklistClient.new.delete(creator, tasklist)
      tasklist.destroy! unless tasklist.new_record?
    else
      User.staff.each do |user|
        tasklist = tasklists.where(user: user).first_or_create
        TasklistClient.new.delete(user, tasklist)
        tasklist.destroy! unless tasklist.new_record?
      end
    end

    discard_tasks!
  end

  def propagate_to_api_by_privacy
    if private?
      User.staff_except(creator).each do |user|
        tasklist = tasklists.where(user: user).first_or_initialize
        TasklistClient.new.delete(user, tasklist) unless tasklist.new_record?
        tasklist.destroy! unless tasklist.new_record?
      end
    else
      User.staff_except(creator).each do |user|
        tasklist = tasklists.where(user: user).first_or_create
        action = tasklist.new_record? ? :insert : :update
        response = TasklistClient.new.send(action, user, tasklist)
        tasklist.update(google_id: response['id'])
        # propegate tasks by visibility
      end
    end
  end

  def discard_tasks!
    tasks.each do |task|
      task.update(discarded_at: discarded_at)
    end
  end
end
