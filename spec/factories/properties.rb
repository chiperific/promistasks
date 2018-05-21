# frozen_string_literal: true

FactoryBot.define do
  factory :property do
    sequence(:name) { |n| "Property #{n}" }
    sequence(:address) { |n| "#{n} Alexander St" }
    sequence(:google_id) { |n| "FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDow#{n}"}
  end
end
