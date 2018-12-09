# frozen_string_literal: true

class Organization < ApplicationRecord
  belongs_to :billing_contact,     class_name: 'User', inverse_of: :organization_billing, optional: true
  belongs_to :maintenance_contact, class_name: 'User', inverse_of: :organization_maintenance, optional: true
  belongs_to :volunteer_contact,   class_name: 'User', inverse_of: :organization_volunteer, optional: true

  validates_presence_of :name, :domain, :default_email, :default_phone

  validate :highlander, if: -> { new_record? }

  def highlander
    errors.add(:name, '[Scottish accent:] There can be only one, highlander. Do not try this again.') unless Organization.count.zero?
  end
end
