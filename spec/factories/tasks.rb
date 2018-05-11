# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Task #{n}" }
    association :creator, factory: :staff
    association :owner, factory: :staff
  end
end
