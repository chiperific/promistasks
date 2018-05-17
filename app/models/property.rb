# frozen_string_literal: true

class Property < ApplicationRecord
  include Discard::Model

  has_many :connections, inverse_of: :property, dependent: :destroy
  has_many :users, through: :connections
  accepts_nested_attributes_for :connections, allow_destroy: true

  has_many :tasks, inverse_of: :property, dependent: :destroy

  has_many :exclude_property_users, inverse_of: :property, dependent: :destroy
  has_many :excluded_users, class_name: :User, through: :exclude_property_users, source: :user
  accepts_nested_attributes_for :exclude_property_users, allow_destroy: true

  validates :name, :address, uniqueness: true, presence: true
  validates_uniqueness_of :certificate_number, :google_id, :serial_number, allow_nil: true

  monetize :cost_cents, :lot_rent_cents, :budget_cents, allow_nil: true

  before_validation :name_and_address
  before_save :default_budget

  # after_create :create_with_api
  # after_update :update_with_api, -> if: { name_changed? } # rails 5.2: { saved_change_to_name? }

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

  def tasklist_users
    User.where.not(id: self.excluded_users.select(:user_id))
  end

  def assign_from_api_fields(tasklist_json)
    name = tasklist['title']
    selflink = tasklist['selfLink']
  end

  private

  def name_and_address
    return true if name.present? && address.present?
    if name.present? && address.blank?
      self.address = name
      true
    elsif name.blank? && address.present?
      self.name = address
      true
    else
      false
    end
  end

  def default_budget
    self.budget = Money.new(7_500_00) if budget.blank?
  end

  def create_with_api
    # for each User.staff
  end

  def update_with_api
    # Handle update and delete(discard) in one method
    # for each User.staff
  end
end
