# frozen_string_literal: true

class Organization < ApplicationRecord
  validates_presence_of :name, :domain, :billing_contact_id, :maintenance_contact_id, :volunteer_contact_id

  validate :highlander

  def highlander
    errors.add(:name, 'There can be only one') if Organization.all.count.positive?
  end
end
