# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Task #{n}" }
    association :creator, factory: :oauth_user
    association :owner, factory: :oauth_user
    property
    sequence(:google_id) { |n| "FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDow#{n}" }
  end
end
