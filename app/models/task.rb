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
  validates_inclusion_of  :needs_more_info, :created_from_api,
                          in: [true, false]
  validates_inclusion_of :visibility, in: [0, 1, 2, 3], message: "must be one of these: #{Constant::Task::VISIBILITY.to_sentence}"
  validates_inclusion_of :priority, in: [0, 1, 2, 3, 4], allow_blank: true, allow_nil: true, message: "must be one of these: #{Constant::Task::PRIORITY.to_sentence}"

  validates :title, presence: true, uniqueness: { scope: :property }

  validate :require_cost, if: -> { budget.present? && cost.nil? && completed_at.present? }
  validate :due_cant_be_past

  monetize :budget_cents, :cost_cents, allow_nil: true, allow_blank: true

  before_validation :visibility_must_be_2, if: -> { property&.is_default? && visibility != 2 }
  before_save       :decide_record_completeness
  after_create      :create_task_users,    unless: -> { discarded_at.present? || created_from_api? }
  after_update      :update_task_users,    if: :saved_changes_to_api_fields?
  after_update      :relocate,             if: -> { saved_change_to_property_id? }
  after_update      :change_task_users,    if: :saved_changes_to_users?
  after_update      :cascade_completed,    if: -> { completed_at.present? && completed_at_before_last_save.nil? }
  after_save        :delete_task_users,    if: -> { discarded_at.present? && discarded_at_before_last_save.nil? }
  after_save        :discard_joined,       if: -> { discarded_at.present? }
  after_save        :undiscard_joined,     if: -> { discarded_at_before_last_save.present? && discarded_at.nil? }

  default_scope { order(:due, :priority, :title) }

  scope :in_process,      -> { undiscarded.where(completed_at: nil) }
  scope :needs_more_info, -> { in_process.where(needs_more_info: true) }
  scope :complete,        -> { undiscarded.where.not(completed_at: nil) }
  scope :has_cost,        -> { undiscarded.where.not(cost_cents: nil) }
  scope :public_visible,  -> { undiscarded.where(visibility: 1) }
  scope :related_to,      ->(user) { where('creator_id = ? OR owner_id = ?', user.id, user.id) }
  scope :visible_to,      ->(user) { related_to(user).or(public_visible) }
  scope :created_since,   ->(time) { where('created_at >= ?', time) }
  scope :due_within,      ->(day_num) { in_process.where('due <= ?', Date.today + day_num.days) }
  scope :due_before,      ->(date) { where('due <= ?', date) }
  scope :past_due,        -> { in_process.where('due < ?', Date.today) }
  scope :not_primary,     -> { joins(:property).where('properties.is_default = FALSE')}

  class << self
    alias archived discarded
    alias active kept
  end

  def status
    completed_at.nil? ? 'active' : 'complete'
  end

  def complete?
    completed_at.present?
  end

  def archived?
    discarded_at.present?
  end

  def on_default?
    property.is_default?
  end

  def budget_remaining
    return nil if budget.nil? && cost.nil?
    temp_budget = budget || Money.new(0)
    temp_cost = cost || Money.new(0)
    temp_budget - temp_cost
  end

  def assign_from_api_fields(task_json)
    return false if task_json.nil?

    tap do |t|
      t.title = task_json['title']
      t.notes = task_json['notes']
      t.completed_at = task_json['completed']
      t.due = task_json['due']
      t.created_from_api = true
    end

    self
  end

  def ensure_task_user_exists_for(user)
    return false if user.oauth_id.nil?
    task_user = task_users.where(user: user).first_or_initialize
    return task_user unless task_user.new_record? || task_user.google_id.nil?
    tasklist = property.ensure_tasklist_exists_for(user)
    task_user.tasklist_gid = tasklist.google_id
    task_user.save
    task_user.reload
  end

  def create_task_users
    [creator, owner].each do |user|
      ensure_task_user_exists_for(user)
    end
  end

  def update_task_users
    # if the users change, then new task_users will be created, which triggers the #api_create on after_create callback
    return false if saved_changes_to_users? || discarded_at.present?
    [creator, owner].each do |user|
      task_user = ensure_task_user_exists_for(user)
      # changing details about the task won't trigger an api call from task_user
      # so it must be triggered here
      task_user.api_update if task_user.present?
    end
  end

  def relocate
    [creator, owner].each do |user|
      tasklist = property.ensure_tasklist_exists_for(user)
      task_user = ensure_task_user_exists_for(user)
      task_user.update(tasklist_gid: tasklist.google_id) if task_user.present?
    end
  end

  def change_task_users
    if creator_id != creator_id_before_last_save
      old_tu = task_users.where(user_id: creator_id_before_last_save)
      old_tu.first.destroy if old_tu.present?
      ensure_task_user_exists_for(creator)
    end

    if owner_id != owner_id_before_last_save
      old_tu = task_users.where(user_id: owner_id_before_last_save)
      old_tu.first.destroy if old_tu.present?
      ensure_task_user_exists_for(owner)
    end
  end

  def cascade_completed
    task_users.each do |tu|
      tu.update(completed_at: completed_at)
    end
  end

  def delete_task_users
    # the task_user#before_destroy callback deletes the task from the API
    # task_users.destroy_all skips callbacks
    task_users.each(&:destroy)
  end

  def saved_changes_to_users?
    saved_change_to_creator_id? || saved_change_to_owner_id?
  end

  def saved_changes_to_api_fields?
    !!saved_change_to_title? ||
      !!saved_change_to_notes? ||
      !!saved_change_to_due? ||
      !!saved_change_to_completed_at?
  end

  def public?
    visibility == 1
  end

  def related_to?(user)
    creator == user ||
      owner == user
  end

  def visible_to?(user)
    visibility == 1 ||
      user.system_admin? ||
      (visibility == 0 && user.staff?) ||
      (visibility == 2 && related_to?(user)) ||
      (visibility == 3 && !user.client?)
  end

  def past_due?
    return false unless due.present? && completed_at.blank?
    due < Date.today
  end

  def priority_color
    case priority
    when 0
      'red lighten-2'
    when 1
      'amber'
    when 2
      'light-green'
    when 3
      'green'
    when 4
      'blue'
    else
      ''
    end
  end

  private

  def visibility_must_be_2
    self.visibility = 2
  end

  def decide_record_completeness
    strikes = 0

    strikes += 3 if due.nil?
    strikes += 1 if priority.nil?
    strikes += 1 if budget.nil?
    strikes += -5 if property.is_default?

    self.needs_more_info = strikes > 3
    true
  end

  def require_cost
    errors.add(:cost, 'must be recorded, or you can delete the budget amount')
  end

  def due_cant_be_past
    return true if due.nil?
    return true if created_from_api?
    if due.past?
      errors.add(:due, 'must be in the future')
      false
    else
      true
    end
  end

  def discard_joined
    skills.each(&:discard)
  end

  def undiscard_joined
    skills.each(&:undiscard)
  end
end
