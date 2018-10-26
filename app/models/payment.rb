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

  serialize :recurrence, IceCube::Schedule

  validates_inclusion_of :method,       in: Constant::Payment::METHODS, message: "must be one of these: #{Constant::Payment::METHODS.to_sentence}", allow_blank: true
  validates_inclusion_of :utility_type, in: Constant::Utility::TYPES, message: "must be one of these: #{Constant::Utility::TYPES.to_sentence}", allow_blank: true
  validates_inclusion_of :paid_to,      in: Constant::Payment::PAID_TO, message: "must be one of these: #{Constant::Payment::PAID_TO.to_sentence}"
  validates_inclusion_of :on_behalf_of, in: Constant::Payment::ON_BEHALF_OF, message: "must be one of these: #{Constant::Payment::ON_BEHALF_OF.to_sentence}"
  validates_inclusion_of :recurring, :send_email_reminders, :suppress_system_alerts,
                         in: [true, false]
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
  scope :past_due,        -> { undiscarded.where('due < ?', Date.today).where(paid: nil) }
  scope :active,          -> { undiscarded.past_due.or(where('due > ?', Date.today)) }
  scope :history,         -> { undiscarded.paid.or(where('due < ?', Date.today).where.not(paid: nil)) }

  after_save :create_next_instance, if: -> { recurrence.present? && recurring && paid.present? && paid_before_last_save.blank? }

  def for
    return nil unless on_behalf_of.present? && Constant::Payment::ON_BEHALF_OF.include?(on_behalf_of)
    public_send(on_behalf_of)
  end

  def from
    return Organization.first unless paid_to == 'organization'
    from = contractor if contractor_id.present?
    from = park if park_id.present?
    from = utility if utility_id.present?
    from = client if client_id.present? && on_behalf_of != 'client'
    from
  end

  def past_due?
    return false unless due.present?
    due.past?
  end

  def status
    if paid.present?
      'Paid on ' + paid.strftime('%b %-d, %Y')
    elsif due.present? && due.future?
      'Due on ' + due.strftime('%b %-d, %Y')
    elsif past_due?
      'PAST DUE as of ' + due.strftime('%b %-d, %Y')
    elsif received.present?
      'Received on' + received.strftime('%b %-d, %Y')
    else
      'No dates set'
    end
  end

  def to
    return nil unless paid_to.present? && Constant::Payment::PAID_TO.include?(paid_to)
    return Organization.first if paid_to == 'organization'
    public_send(paid_to)
  end

  private

  def create_next_instance
    child = dup
    child.tap do |c|
      c.received = nil
      c.paid = nil
      c.discarded_at = nil
      c.payment_amt_cents = nil
      c.suppress_system_alerts = false
      c.created_at = Time.now
      c.due = next_recurrence
    end

    child.save!
  end

  def must_have_association
    return true if property_id.present? ||
                   park_id.present? ||
                   utility_id.present? ||
                   task_id.present? ||
                   contractor_id.present? ||
                   client_id.present?
    errors.add(:bill_amt, 'please select an association')
    false
  end

  def next_recurrence
    return nil unless recurrence.present?
    recurrence.next_occurrence(due).to_date
  end
end
