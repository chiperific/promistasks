# frozen_string_literal: true

class Connection < ApplicationRecord
  include Discard::Model

  belongs_to :user, inverse_of: :connections
  belongs_to :property, inverse_of: :connections

  validates_presence_of :user_id, :property_id, :relationship
  validates :relationship, inclusion: { in: Constant::Connection::RELATIONSHIPS, message: "must be one of these: #{Constant::Connection::RELATIONSHIPS.to_sentence}" }
  validates :stage, inclusion: { in: Constant::Connection::STAGES, allow_blank: true, message: "must be one of these: #{Constant::Connection::STAGES.to_sentence}" }

  validate :relationship_appropriate_for_stage

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
end
