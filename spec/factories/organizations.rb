# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    association :billing_contact, factory: :user
    association :maintenance_contact, factory: :user
    association :volunteer_contact, factory: :user
  end
end
