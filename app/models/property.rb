# frozen_string_literal: true

class Property < ApplicationRecord
  include Discard::Model

  has_many :connections, inverse_of: :property, dependent: :destroy
  has_many :users, through: :connections
  accepts_nested_attributes_for :connections, allow_destroy: true

  has_many :tasks, inverse_of: :property, dependent: :destroy

  validates_presence_of :name
  validates_uniqueness_of :certificate_number, allow_nil: true

  monetize :cost_cents, :lot_rent_cents, :budget_cents, allow_nil: true

  before_save :default_budget

  scope :needs_title, -> { where(certificate_number: nil) }

  def full_address
    addr = address
    addr += ', ' + city unless city.blank?
    addr += ', ' + state unless city.blank?
    addr += ', ' + postal_code
    addr
  end

  def budget_remaining
    budget - tasks.map(&:cost).compact.sum
  end

  def default_budget
    self.budget = Money.new(7_500_00) if budget.blank?
  end
end
