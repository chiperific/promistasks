# frozen_string_literal: true

class Task < ApplicationRecord
  include Discard::Model

  belongs_to :creator,  class_name: 'User', inverse_of: :created_tasks
  belongs_to :owner,    class_name: 'User', inverse_of: :owned_tasks
  belongs_to :subject,  class_name: 'User', inverse_of: :subject_tasks, optional: true

  belongs_to :property, inverse_of: :tasks

  has_many :skill_tasks, inverse_of: :task, dependent: :destroy
  has_many :skills, through: :skill_tasks
  accepts_nested_attributes_for :skill_tasks, allow_destroy: true

  validates_presence_of :creator_id, :owner_id, :property_id
  validates :priority, inclusion: { in: Constant::Task::PRIORITY, allow_blank: true, message: "must be one of these: #{Constant::Task::PRIORITY.to_sentence}" }
  validates_inclusion_of  :license_required, :needs_more_info, :deleted, :hidden,
                          :initialization_template, in: [true, false]
  validates_inclusion_of :status, in: %w[completed needsAction]
  validates_inclusion_of :visibility, in: [0, 1, 2, 3]

  validates :title, uniqueness: true, presence: true
  validates :google_id, uniqueness: true, allow_blank: true

  validate :require_cost
  validate :due_cant_be_past

  monetize :budget_cents, :cost_cents, allow_nil: true

  before_save :decide_completeness
  before_save :sync_deleted_and_discarded_at, if: :unsynced_deleted_discard?
  before_save :sync_completed_fields, if: -> { completed_at.present? || status == 'completed' }
  before_save :copy_position_as_integer, if: -> { position.present? }

  after_create :create_with_api
  after_update :update_with_api, if: :saved_changes_to_api_fields?
  after_update :relocate, if: -> { saved_change_to_property_id? }

  scope :needs_more_info, -> { where(needs_more_info: true).where(initialization_template: false) }
  scope :in_process, -> { where(completed_at: nil).where(initialization_template: false) }
  scope :complete, -> { where.not(completed_at: nil).where(initialization_template: false) }
  scope :descending, -> { order(position_int: :asc) }
  scope :public_visible, -> { where(visibility: 1) }

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

  def assign_from_api_fields!(task_json)
    return false if task_json.empty?

    self.google_id = task_json['id']
    self.title = task_json['title']
    self.google_updated = task_json['updated']
    self.parent_id = task_json['parent']
    self.position = task_json['position']
    self.notes = task_json['notes']
    self.status = task_json['status']
    self.due = task_json['due']
    self.completed_at = task_json['completed']
    self.deleted = task_json['deleted'] || false
    self.hidden = task_json['hidden'] || false

    task_json.present?
  end

  private

  def require_cost
    return true if completed_at.nil?
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

    strikes += 3 if due.nil?
    strikes += 1 if priority.nil?
    strikes += 1 if budget.nil?

    self.needs_more_info = strikes > 3
    true
  end

  def unsynced_deleted_discard?
    return false if !deleted? && discarded_at.blank?
    return false if deleted? && discarded_at.present?
    true
  end

  def sync_deleted_and_discarded_at
    self.discarded_at = Time.now if deleted?
    self.deleted = discarded_at.present? ? true : false
  end

  def sync_completed_fields
    return true if completed_at.present? && status == 'completed'
    self.completed_at = Time.now
    self.status = 'completed'
  end

  def copy_position_as_integer
    self.position_int = position.to_i
  end

  def saved_changes_to_api_fields?
    saved_change_to_title? ||
      saved_change_to_parent_id? ||
      saved_change_to_notes? ||
      saved_change_to_status? ||
      saved_change_to_due? ||
      saved_change_to_completed_at? ||
      saved_change_to_deleted?
  end

  def create_with_api
    taskclient = TaskClient.new

    [owner, creator].each do |user|
      tasklist = Tasklist.where(property: property, user: user)
      taskclient.insert(user, tasklist.tasklist_id, self) if tasklist.present?
    end
  end

  def update_with_api
    taskclient = TaskClient.new
    # Handle update and delete(discard) in one method
    action = discarded_at.present? ? :delete : :update

    [owner, creator].each do |user|
      tasklist = Tasklist.where(property: property, user: user)
      taskclient.send(action, user, tasklist.tasklist_id, self) if tasklist.present?
    end
  end

  def relocate
    [owner, creator].each do |user|
      tasklist = Tasklist.where(property: property, user: user)
      TaskClient.new.relocate(user, tasklist.tasklist_id, self) if tasklist.present?
    end
  end
end
