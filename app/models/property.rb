# frozen_string_literal: true

class Property < ApplicationRecord
  include Discard::Model

  has_many :connections, inverse_of: :property, dependent: :destroy
  has_many :users, through: :connections
  accepts_nested_attributes_for :connections, allow_destroy: true

  belongs_to :creator, class_name: 'User', inverse_of: :created_properties

  has_many :tasks, inverse_of: :property, dependent: :destroy

  validates_presence_of :creator_id
  validates :name, :address, uniqueness: true, presence: true
  validates_uniqueness_of :certificate_number, :google_id, :serial_number, allow_nil: true
  validates_inclusion_of :private, in: [true, false]

  monetize :cost_cents, :lot_rent_cents, :budget_cents, allow_nil: true

  before_validation :name_and_address, if: :unsynced_name_address?
  before_save :default_budget
  after_create :create_with_api, if: :not_discarded?
  after_update :update_with_api
  after_update :propagate_to_api_by_privacy, if: -> { saved_change_to_private? }
  after_save   :discard_tasks!, if: -> { discarded_at.present? }

  scope :needs_title, -> { where(certificate_number: nil) }

  def full_address
    addr = address
    addr += ', ' + city unless city.blank?
    addr += ', ' + state unless city.blank?
    addr += ', ' + postal_code unless postal_code.blank?
    addr
  end

  def budget_remaining
    budget - tasks.map(&:cost).compact.sum
  end

  def assign_from_api_fields!(tasklist_json)
    self.google_id = tasklist_json['id']
    self.name = tasklist_json['title']
    self.selflink = tasklist_json['selfLink']
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
      TasklistClient.new.insert(creator, self)
    else
      User.staff.each do |user|
        TasklistClient.new.insert(user, self)
      end
    end
  end

  def update_with_api
    # Handle update and delete(discard) in one method
    return true if !saved_change_to_name? && discarded_at.blank?

    tasklist = TasklistClient.new
    action = discarded_at.present? ? :delete : :update

    if private?
      tasklist.send(action, creator, self)
    else
      User.staff.each do |user|
        tasklist.send(action, user, self)
      end
    end
  end

  def propagate_to_api_by_privacy
    tasklist = TasklistClient.new
    action = private? ? :delete : :insert

    User.staff_except(creator).each do |user|
      tasklist.send(action, user, self)
    end

    # if insert, should also propegate the tasks
  end

  def discard_tasks!
    tasks.each do |task|
      task.update(discarded_at: discarded_at)
    end
  end
end
