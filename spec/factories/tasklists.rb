# frozen_string_literal: true

FactoryBot.define do
  factory :tasklist do
    user
    property
    sequence(:google_id) { |n| "FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDow#{n}" }
  end
end
