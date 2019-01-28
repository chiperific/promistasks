# frozen_string_literal: true

FactoryBot.define do
  factory :tasklist do
    association :user, factory: :oauth_user
    google_id { 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6NTYwMTU5MzkyNjA5MzM2Mzow' }
    property
  end
end
