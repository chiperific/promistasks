# frozen_string_literal: true

FactoryBot.define do
  factory :property do
    sequence(:name) { |n| "Property #{n}" }
    sequence(:address) { |n| "#{n} Alexander St" }
    park
    association :creator, factory: :oauth_user
  end

  factory :property_ready, class: Property do
    sequence(:name) { |n| "Property #{n}" }
    sequence(:address) { |n| "#{n} Alexander St" }
    park
    stage 'complete'
    association :creator, factory: :oauth_user
  end
end
