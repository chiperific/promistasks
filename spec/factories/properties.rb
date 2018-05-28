# frozen_string_literal: true

FactoryBot.define do
  factory :property do
    sequence(:name) { |n| "Property #{n}" }
    sequence(:address) { |n| "#{n} Alexander St" }
    association :creator, factory: :oauth_user
  end
end
