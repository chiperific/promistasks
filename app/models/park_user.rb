# frozen_string_literal: true

class ParkUser < ApplicationRecord
  belongs_to :park, inverse_of: :park_users
  belongs_to :user, inverse_of: :park_users

  validates_presence_of :park, :user

  validates :relationship, presence: true, inclusion: { in: Constant::Connection::RELATIONSHIPS, message: "must be one of these: #{Constant::Connection::RELATIONSHIPS.to_sentence}" }

  before_validation :relationship_must_match_user_type

  private

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
end
