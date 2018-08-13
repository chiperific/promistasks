# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    association :billing_contact, factory: :user, name: 'Billing Contact', email: 'billing@contact.com'
    association :maintenance_contact, factory: :user, name: 'Maintenance Contact', email: 'maintenance@contact.com'
    association :volunteer_contact, factory: :user, name: 'Volunteer Contact', email: 'volunteer@contact.com'
  end
end
