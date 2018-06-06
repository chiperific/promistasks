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

  has_many :task_users, inverse_of: :task, dependent: :destroy
  has_many :users, through: :task_users
  accepts_nested_attributes_for :task_users, allow_destroy: true

  validates_presence_of :creator_id, :owner_id, :property_id
  validates :priority, inclusion: { in: Constant::Task::PRIORITY, allow_blank: true, message: "must be one of these: #{Constant::Task::PRIORITY.to_sentence}" }
  validates_inclusion_of  :license_required, :needs_more_info, :deleted, :hidden,
                          :initialization_template, in: [true, false]
  validates_inclusion_of :status, in: %w[completed needsAction]
  validates_inclusion_of :visibility, in: [0, 1, 2, 3]

  validates :title, presence: true, uniqueness: { scope: :property }

  validate :require_cost
  validate :due_cant_be_past

  monetize :budget_cents, :cost_cents, allow_nil: true

  before_save :decide_completeness
  before_save :sync_deleted_and_discarded_at, if: :unsynced_deleted_discard?
  before_save :sync_completed_fields, if: -> { completed_at.present? || status == 'completed' }

  after_create :create_with_api
  after_update :create_with_api, if: :saved_changes_to_users?
  after_update :update_with_api, if: :saved_changes_to_api_fields?
  after_update :relocate, if: -> { saved_change_to_property_id? }

  scope :needs_more_info, -> { undiscarded.where(needs_more_info: true).where(initialization_template: false) }
  scope :in_process, -> { undiscarded.where(completed_at: nil).where(initialization_template: false) }
  scope :complete, -> { undiscarded.where.not(completed_at: nil).where(initialization_template: false) }
  scope :public_visible, -> { undiscarded.where(visibility: 1) }

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
    return false if task_json.nil?

    tap do |t|
      t.notes = task_json['notes']
      t.status = task_json['status']
      t.due = task_json['due']
      t.deleted = task_json['deleted'] || false
      t.hidden = task_json['hidden'] || false
      t.completed_at = task_json['completed']
    end

    task_json.present?
  end

  def create_taskuser_for(user, action = :insert)
    tasklist = Tasklist.where(property: property, user: user).first
    task_user = task_users.where(user: user).first_or_initialize
    return 'already exists' if task_user.google_id.present?
    response = TaskClient.new.send(
      action,
      user: user,
      tasklist_gid: tasklist.google_id,
      task: self
    )
    task_user.assign_from_api_fields!(response)
    task_user.tasklist_id = tasklist.google_id
    task_user.save
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

  def saved_changes_to_api_fields?
    saved_change_to_title? ||
      saved_change_to_notes? ||
      saved_change_to_due? ||
      saved_change_to_status? ||
      saved_change_to_deleted? ||
      saved_change_to_completed_at?
  end

  def saved_changes_to_users?
    saved_change_to_creator_id? || saved_change_to_owner_id?
  end

  def prepare_for_api
    [creator, owner].each do |user|
      Property.find(property_id_before_last_save).create_tasklist_for(user) if property_id_before_last_save.present?
      property.create_tasklist_for(user)
      create_taskuser_for(user)
    end
  end

  def create_with_api
    prepare_for_api
  end

  def update_with_api
    prepare_for_api
    action = discarded_at.present? ? :delete : :update

    [creator, owner].each do |user|
      task_user = task_users.where(user: user).first
      response = TaskClient.new.send(
        action,
        user: user,
        tasklist_gid: task_user.tasklist_id,
        task: self,
        task_gid: task_user.google_id
      )

      if action == :delete
        task_user.destroy
      else
        task_user.assign_from_api_fields!(response)
        task_user.save
      end
    end

    task_users.where(user_id: creator_id_before_last_save).first.destroy if saved_change_to_creator_id?
    task_users.where(user_id: owner_id_before_last_save).frst.destroy    if saved_change_to_owner_id?
  end

  def relocate
    prepare_for_api
    [creator, owner].each do |user|
      old_tasklist = Tasklist.where(property_id: property_id_before_last_save, user: user).first
      tasklist = Tasklist.where(property: property, user: user).first
      task_user = task_users.where(user: user).first
      TaskClient.new.relocate(user: user, old_list_gid: old_tasklist.google_id, new_list_gid: tasklist.google_id, task: self, task_gid: task_user.google_id) if task_user.tasklist_id.present?
    end
  end
end
