# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    park
    property
    paid_to { 'park' }
    on_behalf_of { 'property' }
    bill_amt { 400 }
    received { Date.today }
    due { Date.today + 15.days }
    association :creator, factory: :user
    utility_type { Constant::Utility::TYPES.sample }
  end

  factory :payment_utility, class: Payment do
    utility
    property
    paid_to { 'utility' }
    on_behalf_of { 'property' }
    bill_amt { 400 }
    received { Date.today }
    due { Date.today + 15.days }
    association :creator, factory: :user
    utility_type { Constant::Utility::TYPES.sample }
  end

  factory :payment_park, class: Payment do
    park
    association :client, factory: :client_user
    paid_to { 'park' }
    on_behalf_of { 'client' }
    bill_amt { 400 }
    received { Date.today }
    due { Date.today + 15.days }
    association :creator, factory: :user
    utility_type { Constant::Utility::TYPES.sample }
  end

  factory :payment_contractor, class: Payment do
    association :contractor, factory: :contractor_user
    association :client, factory: :client_user
    paid_to { 'contractor' }
    on_behalf_of { 'client' }
    bill_amt { 400 }
    received { Date.today }
    due { Date.today + 15.days }
    association :creator, factory: :user
    utility_type { Constant::Utility::TYPES.sample }
  end

  factory :payment_client, class: Payment do
    association :client, factory: :client_user
    property
    paid_to { 'client' }
    on_behalf_of { 'property' }
    bill_amt { 400 }
    received { Date.today }
    due { Date.today + 15.days }
    association :creator, factory: :user
    utility_type { Constant::Utility::TYPES.sample }
  end

  factory :payment_org, class: Payment do
    utility
    property
    paid_to { 'organization' }
    on_behalf_of { 'property' }
  end
end
