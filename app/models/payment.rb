# frozen_string_literal: true

class Payment < ApplicationRecord
  include Discard::Model
  include IceCube

  belongs_to :property, inverse_of: :payments, optional: true
  belongs_to :park,     inverse_of: :payments, optional: true
  belongs_to :utility,  inverse_of: :payments, optional: true
  belongs_to :task,     inverse_of: :payments, optional: true
  belongs_to :contractor, class_name: 'User', inverse_of: :contractor_payments, optional: true
  belongs_to :client,     class_name: 'User', inverse_of: :client_payments, optional: true
  belongs_to :creator,    class_name: 'User', inverse_of: :created_payments

  monetize :bill_amt_cents
  monetize :payment_amt_cents, allow_nil: true, allow_blank: true

  validates_inclusion_of :method, in: Constant::Payment::METHODS, message: "must be one of these: #{Constant::Payment::METHODS.to_sentence}", allow_blank: true
  validates_inclusion_of :utility_type, in: Constant::Utility::TYPES, message: "must be one of these: #{Constant::Utility::TYPES.to_sentence}", allow_blank: true
  validates_presence_of :creator_id

  validate :must_have_association

  scope :active,          -> { undiscarded.where(paid: nil) }
  scope :for_properties,  -> { undiscarded.where.not(property_id: nil) }
  scope :for_parks,       -> { undiscarded.where.not(park_id: nil) }
  scope :for_utilities,   -> { undiscarded.where.not(utility_id: nil) }
  scope :for_tasks,       -> { undiscarded.where.not(task_id: nil) }
  scope :for_contractors, -> { undiscarded.where.not(contractor_id: nil) }
  scope :for_clients,     -> { undiscarded.where.not(client_id: nil) }
  scope :paid,            -> { undiscarded.where.not(paid: nil) }
  scope :past_due,        -> { undiscarded.where('due < ?', Date.today) }

  before_save :recurrence_sets_recurring
  after_save  :create_next_instance, if: -> { recurrence.present? && recurring.present? && paid.present? && paid_before_last_save.blank? }

  class << self
    alias archived discarded
    alias active kept
  end

  def create_next_instance
    child = dup
    child.tap do |c|
      c.received = nil
      c.paid = nil
      c.discarded_at = nil
      c.payment_amt_cents = nil
      c.created_at = Time.now
      c.due = next_recurrence
      c.save
    end
  end

  def must_have_association
    return true if property_id.present? ||
                   park_id.present? ||
                   utility_id.present? ||
                   task_id.present? ||
                   contractor_id.present? ||
                   client_id.present?
    error.add(:bill_amt, 'please select an association')
  end

  def next_recurrence
    return nil unless recurrence.present?
    schedule = Schedule.from_yaml(recurrence)
    schedule.next_occurrence(due).to_date
  end

  def recurrence_sets_recurring
    self.recurring = recurrence.present?
  end
end
