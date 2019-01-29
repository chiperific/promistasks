# frozen_string_literal: true

class Task < ApplicationRecord
  include Discard::Model

  belongs_to :creator,  class_name: 'User', inverse_of: :created_tasks
  belongs_to :owner,    class_name: 'User', inverse_of: :owned_tasks
  belongs_to :subject,  class_name: 'User', inverse_of: :subject_tasks, optional: true

  belongs_to :property, inverse_of: :tasks

  has_many :payments, inverse_of: :task, dependent: :destroy

  has_many :skill_tasks, inverse_of: :task, dependent: :destroy
  has_many :skills, through: :skill_tasks
  accepts_nested_attributes_for :skill_tasks, allow_destroy: true

  has_many :task_users, inverse_of: :task, dependent: :destroy
  has_many :users, through: :task_users
  accepts_nested_attributes_for :task_users, allow_destroy: true

  validates :title, presence: true, uniqueness: { scope: :property }
  validates_presence_of :creator_id, :owner_id, :property_id, :min_volunteers, :max_volunteers
  validates_inclusion_of  :needs_more_info, :created_from_api, :professional, :volunteer_group,
                          in: [true, false]
  validates_inclusion_of :visibility, in: [0, 1, 2, 3], message: "must be one of these: #{Constant::Task::VISIBILITY.to_sentence}"
  validates_inclusion_of :priority, in: [0, 1, 2, 3, 4], allow_blank: true, allow_nil: true, message: "must be one of these: #{Constant::Task::PRIORITY.to_sentence}"

  monetize :budget_cents, :cost_cents, allow_nil: true, allow_blank: true

  validate :due_must_be_after_created
  validate :require_cost, if: -> { budget.present? && cost.nil? && completed_at.present? }

  before_validation :visibility_must_be_2, if: -> { property&.is_default? && visibility != 2 }
  before_save       :decide_record_completeness
  after_save        :create_task_users,    if: -> { discarded_at.blank? && created_locally? && id_before_last_save.nil? }
  after_update      :update_task_users,    if: :saved_changes_to_api_fields?
  after_update      :relocate,             if: -> { saved_change_to_property_id? }
  after_update      :change_task_users,    if: :saved_changes_to_users?
  after_update      :cascade_completed,    if: -> { completed_at.present? && completed_at_before_last_save.nil? }

  default_scope { order(:due, :priority, :title) }

  class << self
    alias archived discarded
    alias active kept
  end

  scope :complete,        -> { active.where.not(completed_at: nil) }
  scope :created_since,   ->(time) { in_process.where("#{table_name}.created_at >= ?", time) }
  scope :due_within,      ->(day_num) { in_process.where(due: Date.today..(Date.today + day_num.days)) }
  scope :except_primary,  -> { joins(:property).where('properties.is_default = FALSE') }
  scope :has_cost,        -> { active.where.not(cost_cents: nil) }
  scope :in_process,      -> { active.where(completed_at: nil) }
  scope :needs_more_info, -> { in_process.where(needs_more_info: true) }
  scope :past_due,        -> { in_process.where("#{table_name}.due < ?", Date.today) }
  scope :public_visible,  -> { active.where(visibility: 1) }
  scope :related_to,      ->(user) { where("#{table_name}.creator_id = ? OR #{table_name}.owner_id = ?", user.id, user.id) }
  scope :visible_to,      ->(user) { related_to(user).or(public_visible) }

  def active?
    completed_at.blank?
  end

  def archived?
    discarded_at.present?
  end

  def assign_from_api_fields(task_json)
    return false if task_json.blank?

    tap do |t|
      t.title = task_json['title']
      t.notes = task_json['notes']&.gsub(/\[.{1,}\]/, '') # see TaskUser#api_body, strip out the things that have been added to notes
      t.completed_at = task_json['completed']
      t.due = task_json['due']
      t.created_from_api = true
    end

    self
  end

  def budget_remaining
    return nil if budget.blank? && cost.blank?
    temp_budget = budget || Money.new(0)
    temp_cost = cost || Money.new(0)
    temp_budget - temp_cost
  end

  def cascade_completed
    task_users.each do |tu|
      tu.update(completed_at: completed_at)
    end
  end

  def change_task_users
    if creator_id != creator_id_before_last_save
      old_tu = task_users.where(user_id: creator_id_before_last_save, scope: 'creator')
      old_tu.first.destroy if old_tu.present?
      ensure_task_user_exists_for(creator)
    end

    if owner_id != owner_id_before_last_save
      old_tu = task_users.where(user_id: owner_id_before_last_save, scope: 'owner')
      old_tu.first.destroy if old_tu.present?
      ensure_task_user_exists_for(owner)
    end
  end

  def complete?
    completed_at.present?
  end

  def create_task_users
    [creator, owner].each do |user|
      ensure_task_user_exists_for(user)
    end
  end

  def created_locally?
    created_from_api == false
  end

  def ensure_task_user_exists_for(user)
    return false if user.oauth_id.nil?

    task_user = task_users.where(user: user).first_or_initialize
    return task_user unless task_user.new_record? || task_user.google_id.blank?

    # tasklist = property.ensure_tasklist_exists_for(user)
    tasklist = property.tasklists.where(user: user).first_or_initialize
    tasklist.save!
    tasklist.reload

    return false if tasklist.google_id.blank?

    task_user.tasklist_gid = tasklist.google_id

    if creator == owner
      task_user.scope = 'both'
    else
      task_user.scope = creator == user ? 'creator' : 'owner'
    end

    task_user.save
    task_user.reload
  end

  def name
    title
  end

  def on_default?
    property.is_default?
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

  def public?
    visibility == 1
  end

  def related_to?(user)
    creator == user ||
      owner == user
  end

  def relocate
    [creator, owner].each do |user|
      tasklist = property.ensure_tasklist_exists_for(user)
      task_user = ensure_task_user_exists_for(user)
      task_user.update(tasklist_gid: tasklist.google_id) if task_user.present?
    end
  end

  def saved_changes_to_api_fields?
    !!saved_change_to_title? ||
      !!saved_change_to_notes? ||
      !!saved_change_to_due? ||
      !!saved_change_to_completed_at?
  end

  def saved_changes_to_users?
    saved_change_to_creator_id? || saved_change_to_owner_id?
  end

  def status
    completed_at.nil? ? 'active' : 'complete'
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

  def visible_to?(user)
    visibility == 1 ||
      user.admin? ||
      (visibility == 0 && user.staff?) ||
      (visibility == 2 && related_to?(user)) ||
      (visibility == 3 && !user.client?)
  end

  def visible_to
    Constant::Task::VISIBILITY[visibility]
  end

  def volunteer_sentence
    return nil if !min_volunteers.positive? && !max_volunteers.positive?

    if min_volunteers.positive? && max_volunteers.positive?
      min_volunteers.to_s + ' to ' + max_volunteers.to_s
    elsif min_volunteers.positive?
      'at least ' + min_volunteers.to_s
    else
      'no more than ' + max_volunteers.to_s
    end
  end

  private

  def decide_record_completeness
    strikes = 0
    strikes += 3 if due.nil?
    strikes += 2 if estimated_hours.blank? || estimated_hours.zero?
    strikes += 1 if priority.nil?
    strikes += 1 if budget.nil?
    strikes += 1 if min_volunteers.nil?
    strikes += 1 if max_volunteers.nil?
    strikes -= 9 if property&.is_default?

    self.needs_more_info = strikes > 3
    true
  end

  def due_must_be_after_created
    return true if due.nil? || created_from_api?

    comparison = created_at.present? ? created_at : Date.today

    if due < comparison.to_date
      errors.add(:due, 'must be in the future')
      false
    else
      true
    end
  end

  def require_cost
    errors.add(:cost, 'must be recorded, or you can delete the budget amount')
  end

  def visibility_must_be_2
    self.visibility = 2
  end
end
