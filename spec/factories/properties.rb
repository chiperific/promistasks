# frozen_string_literal: true

FactoryBot.define do
  sequence :name do |n|
    "Property #{n}"
  end

  sequence :address do |n|
    "#{n} Alexander St"
  end

  factory :property do
    name
    address
    association :creator, factory: :oauth_user
  end

  factory :property_ready, class: Property do
    name
    address
    stage 'complete'
    association :creator, factory: :oauth_user
  end
end
