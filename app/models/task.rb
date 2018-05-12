# frozen_string_literal: true

class Task < ApplicationRecord
  include Discard::Model

  belongs_to :creator,  class_name: 'User', inverse_of: :created_tasks
  belongs_to :owner,    class_name: 'User', inverse_of: :owned_tasks
  belongs_to :subject,  class_name: 'User', inverse_of: :subject_tasks, optional: true

  belongs_to :property, inverse_of: :tasks, optional: true

  has_many :skill_tasks, inverse_of: :task, dependent: :destroy
  has_many :skills, through: :skill_tasks
  accepts_nested_attributes_for :skill_tasks, allow_destroy: true

  validates_presence_of :creator_id, :owner_id
  validates :priority, inclusion: { in: Constant::Task::PRIORITY, allow_blank: true, message: "must be one of these: #{Constant::Task::PRIORITY.to_sentence}" }
  validates_inclusion_of  :license_required, :needs_more_info, :deleted, :hidden,
                          :initialization_template, in: [true, false]
  validates_inclusion_of :visibility, in: [0, 1, 2, 3]

  validates :title, uniqueness: true, presence: true
  validates :google_id, :position, uniqueness: true, allow_blank: true

  validate :require_cost
  validate :due_cant_be_past

  monetize :budget_cents, :cost_cents, allow_nil: true

  before_save :decide_completeness
  before_save :sync_completed_fields, if: -> { completed || status == 'completed'}

  # after_create :create_with_api
  # after_update :update_with_api, if: :api_fields_changed?

  scope :needs_more_info, -> { where(needs_more_info: true).where(initialization_template: false) }
  scope :in_process, -> { where(completed: nil).where(initialization_template: false) }
  scope :complete, -> { where.not(completed: nil).where(initialization_template: false) }

  def budget_remaining
    return nil if budget.nil? && cost.nil?
    temp_budget = budget || Money.new(0)
    temp_cost = cost || Money.new(0)
    temp_budget - temp_cost
  end

  def priority_enum
    Constant::Task::PRIORITY
  end

  def owner_type_enum
    Constant::Task::OWNER_TYPES
  end

  private

  def require_cost
    return true if completed.nil?
    if budget.present? && cost.nil?
      errors.add(:cost, 'must be recorded, or you can delete the budget amount')
      false
    else
      true
    end
  end

  def due_cant_be_past
    return true if due.nil?
    if due.past?
      errors.add(:due, 'must be in the future')
      false
    else
      true
    end
  end

  def decide_completeness
    strikes = 0

    strikes += 4 if due.nil?
    strikes += 2 if priority.nil?
    strikes += 2 if budget.nil?
    strikes += 1 if property_id.nil?

    self.needs_more_info = strikes >= 4
    true
  end

  def sync_completed_fields
    return true if completed && status == 'completed'
    self.completed = true
    self.status = 'completed'
  end

  def api_fields_changed?
    # rails 5.2: { saved_change_to_title? || saved_change_to_notes? || saved_change_to_due? || saved_changed_to_completed? || saved_changed_to_deleted? || saved_changed_to_hidden? || saved_changed_to_position? || saved_changed_to_parent_id? }
    title_changed? ||
      notes_changed? ||
      due_changed? ||
      completed_changed? ||
      deleted_changed? ||
      hidden_changed? ||
      position_changed? ||
      parent_id_changed?
  end

  def create_with_api
    # for each User.staff where owner || creator
  end

  def update_with_api
    # for each User.staff where owner || creator
  end
end
