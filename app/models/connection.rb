# frozen_string_literal: true

class Connection < ApplicationRecord
  include Discard::Model

  belongs_to :user, inverse_of: :connections
  belongs_to :property, inverse_of: :connections

  validates_presence_of :relationship, :user_id, :property_id
  validates :relationship, inclusion: { in: Constant::Connection::RELATIONSHIPS, message: "must be one of these: #{Constant::Connection::RELATIONSHIPS.to_sentence}" }
  validates :stage, inclusion: { in: Constant::Connection::STAGES, allow_blank: true, message: "must be one of these: #{Constant::Connection::STAGES.to_sentence}" }

  before_validation :relationship_appropriate_for_stage, if: -> { stage.present? && relationship != 'tennant' }
  before_validation :relationship_must_match_user_type,  if: -> { relationship.present? }
  before_validation :stage_date_and_stage,               if: -> { stage.present? || stage_date.present? }
  after_save :archive_property,                          if: -> { stage == 'transferred title' }
  # ^ is this too aggressive to do automatically?

  scope :except_tennants, -> { kept.where.not(relationship: 'tennant').order(:created_at) }
  scope :only_tennants,   -> { kept.where(relationship: 'tennant').order(stage_date: :desc) }

  class << self
    alias archived discarded
    alias active kept
  end

  def archived?
    discarded_at.present?
  end

  private

  def archive_property
    property.discard if property.stage == 'complete' && property.tasks.in_process.count.zero?
  end

  def relationship_appropriate_for_stage
    errors.add(:relationship, 'must be "Tennant" to use a stage')
  end

  def relationship_must_match_user_type
    return false if user_id.blank?
    case relationship
    when 'tennant'
      errors.add(:relationship, ': only Clients can be tenants') unless user.client?
    when 'staff contact'
      errors.add(:relationship, ': only Staff can be staff contacts') unless user.staff?
    when 'contractor'
      errors.add(:relationship, ': only Contractors can be listed') unless user.contractor?
    when 'volunteer'
      errors.add(:relationship, ': only Volunteers can be listed') unless user.volunteer?
    end
  end

  def stage_date_and_stage
    errors.add(:stage, 'Please select stage or delete date') if stage.blank?
    errors.add(:stage_date, 'Please enter date or delete stage') if stage_date.blank?
  end
end
