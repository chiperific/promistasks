# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Task #{n}" }
    association :creator, factory: :oauth_user
    association :owner, factory: :oauth_user
    property
  end
end
