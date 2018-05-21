# frozen_string_literal: true

class Connection < ApplicationRecord
  include Discard::Model

  belongs_to :user, inverse_of: :connections
  belongs_to :property, inverse_of: :connections

  validates_presence_of :user_id, :property_id, :relationship
  validates :relationship, inclusion: { in: Constant::Connection::RELATIONSHIPS, message: "must be one of these: #{Constant::Connection::RELATIONSHIPS.to_sentence}" }
  validates :stage, inclusion: { in: Constant::Connection::STAGES, allow_blank: true, message: "must be one of these: #{Constant::Connection::STAGES.to_sentence}" }

  validate :relationship_appropriate_for_stage
  validate :relationship_must_match_user_type
  validate :stage_date_and_stage

  def relationship_enum
    Constant::Connection::RELATIONSHIPS
  end

  def stage_enum
    Constant::Connection::STAGES
  end

  private

  def relationship_appropriate_for_stage
    return true unless stage.present?
    if relationship == 'tennant'
      true
    else
      errors.add(:relationship, 'To use a stage, the relationship should be "Tennant"')
      false
    end
  end

  def relationship_must_match_user_type
    return true if user.nil?
    case relationship
    when 'tennant'
      return true if user.type.include? 'Client'
      errors.add(:relationship, '-> only clients can be tenants')
    when 'staff contact'
      return true unless (user.type & ['Program Staff', 'Project Staff', 'Admin Staff']).empty?
      errors.add(:relationship, '-> only Program, Project or Admin staff can be staff contacts')
    when 'contractor'
      return true if user.type.include? 'Contractor'
      errors.add(:relationship, '-> only Contractors can be used')
    when 'volunteer'
      return true if user.type.include? 'Volunteer'
      errors.add(:relationship, '-> only Volunteers can be used')
    end

    return false if errors[:relationship].present?
  end

  def stage_date_and_stage
    return true if stage_date.nil? && stage.nil?

    errors.add(:stage_date, 'Please enter date or delete stage') if stage_date.nil? && stage.present?
    errors.add(:stage, 'Please select stage or delete date') if stage_date.present? && stage.nil?

    return false if errors[:stage].present? || errors[:stage_date].present?
    true
  end
end