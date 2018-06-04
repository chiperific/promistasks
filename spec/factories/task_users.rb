# frozen_string_literal: true

FactoryBot.define do
  factory :task_user do
    task
    association :user, factory: :oauth_user
    sequence(:google_id) { |n| "FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDow#{n}" }
    # position: '00000000000000046641'
  end
end
