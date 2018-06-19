# frozen_string_literal: true

FactoryBot.define do
  factory :tasklist do
    association :user, factory: :oauth_user
    property
  end
end
