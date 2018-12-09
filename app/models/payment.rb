# frozen_string_literal: true

class Payment < ApplicationRecord
include Discard::Model

  belongs_to :property, inverse_of: :payments, optional: true
  belongs_to :park,     inverse_of: :payments, optional: true
  belongs_to :utility,  inverse_of: :payments, optional: true
  belongs_to :task,     inverse_of: :payments, optional: true
  belongs_to :contractor, class_name: 'User', inverse_of: :contractor_payments, optional: true
  belongs_to :client,     class_name: 'User', inverse_of: :client_payments, optional: true
  belongs_to :creator,    class_name: 'User', inverse_of: :created_payments

  monetize :bill_amt_cents
  monetize :payment_amt_cents, allow_nil: true, allow_blank: true

  validates_presence_of :creator_id

  validates_inclusion_of :method,       in: Constant::Payment::METHODS, message: "must be one of these: #{Constant::Payment::METHODS.to_sentence}", allow_blank: true
  validates_inclusion_of :on_behalf_of, in: Constant::Payment::ON_BEHALF_OF, message: "must be one of these: #{Constant::Payment::ON_BEHALF_OF.to_sentence}"
  validates_inclusion_of :paid_to,      in: Constant::Payment::PAID_TO, message: "must be one of these: #{Constant::Payment::PAID_TO.to_sentence}"
  validates_inclusion_of :recurrence,   in: Constant::Payment::RECURRENCE, message: "must be one of these: #{Constant::Payment::RECURRENCE.to_sentence}", allow_blank: true
  validates_inclusion_of :utility_type, in: Constant::Utility::TYPES, message: "must be one of these: #{Constant::Utility::TYPES.to_sentence}", allow_blank: true
  validates_inclusion_of :recurring, :send_email_reminders, :suppress_system_alerts,
                         in: [true, false]

  validate :must_have_association

  default_scope { order(:due) }

  class << self
    alias archived discarded
    alias active kept
  end

  # scope :for_properties,  -> { active.where.not(property_id: nil) }
  # scope :for_parks,       -> { active.where.not(park_id: nil) }
  # scope :for_utilities,   -> { active.where.not(utility_id: nil) }
  # scope :for_tasks,       -> { active.where.not(task_id: nil) }
  # scope :for_contractors, -> { active.where.not(contractor_id: nil) }
  # scope :for_clients,     -> { active.where.not(client_id: nil) }

  # scope :created_since, ->(time) { active.where("#{table_name}.created_at >= ?", time) }

  scope :due_in_future, -> { active.where('due >= ?', Date.today) }
  scope :due_in_past,   -> { active.where('due < ?', Date.today) }

  scope :paid,          -> { active.where.not(paid: nil) }
  scope :not_paid,      -> { active.where(paid: nil) }
  scope :due_within,    ->(day_num) { not_paid.where(due: Date.today..(Date.today + day_num.days)) }
  scope :past_due,      -> { not_paid.due_in_past }

  scope :related_by_property_to, ->(user) { active.where(property_id: Property.select(:id).related_to(user)) }
  scope :related_by_task_to,     ->(user) { active.where(task_id: Task.select(:id).related_to(user)) }
  scope :related_to,             ->(user) { active.related_by_property_to(user).or(related_by_task_to(user)) }


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

  def manage_relationships(payment_params)
    remove_relationships
    # manage relations individually, regardless of what gets sent from the form
    case payment_params[:paid_to]
    when 'utility'
      self.utility_id = payment_params[:utility_id]
    when 'park'
      self.park_id = payment_params[:park_id]
    when 'contractor'
      self.contractor_id = payment_params[:contractor_id]
    when 'client'
      self.client_id = payment_params[:client_id]
    end

    case payment_params[:on_behalf_of]
    when 'property'
      self.property_id = payment_params[:property_id]
    when 'client'
      self.client_id = payment_params[:client_id_obo]
    end

    self.task_id = payment_params[:task_id] unless payment_params[:task_id] == '0' || payment_params[:task_id] == 0 || payment_params[:task_id].blank?
  end

  def past_due?
    return false unless due.present?

    due.past?
  end

  def reason
    if utility_type.present?
      utility_type
    elsif task.present?
      task.title
    else
      'Unknown'
    end
  end

  def status
    if paid.present?
      'Paid on ' + paid.strftime('%b %-d, %Y')
    elsif due.present? && due.future?
      'Due on ' + due.strftime('%b %-d, %Y')
    elsif past_due?
      'PAST DUE as of ' + due.strftime('%b %-d, %Y')
    elsif received.present?
      'Received on ' + received.strftime('%b %-d, %Y')
    else
      'No dates set'
    end
  end

  def target
    # form field
    to
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
    case to.class.to_s
    when 'Utility'
      errors.add(:utility, 'Please select a Utility from the list') if :utility_id.blank?
    when 'Park'
      errors.add(:park, 'Please select a Park from the list') if :park_id.blank?
    when 'User'
      errors.add(:contractor, 'Please select a Contractor from the list') if :contractor_id.blank?
      errors.add(:client, 'Please select a Client from the list') if :client_id.blank?
    when 'NilClass'
      errors.add(:paid_to, 'Please select a Utility, Park, Contractor or Client')
    end

    case self.for.class.to_s
    when 'User'
      errors.add(:client_id_obo, 'Please select a Client from the list') if :client_id.blank? && on_behalf_of == 'client'
    when 'Property'
      errors.add(:property, 'Please select a Property from the list') if :property_id.blank?
    when 'NilClass'
      errors.add(:on_behalf_of, 'Please select a Property or Client')
    end

    return false if errors.any?

    true
  end

  def next_recurrence
    return nil unless recurrence.present?

    case recurrence
    when 'month'
      due + 1.month
    when '3 months'
      due + 3.months
    when '6 months'
      due + 6.months
    when 'year'
      due + 1.year
    end
  end

  def remove_relationships
    self.utility_id = nil
    self.park_id = nil
    self.contractor_id = nil
    self.client_id = nil
    self.property_id = nil
    self.task_id = nil
  end
end
