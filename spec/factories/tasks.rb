# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Task #{n}" }
    association :creator, factory: :user
    association :owner, factory: :user
  end
end
