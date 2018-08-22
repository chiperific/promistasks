# frozen_string_literal: true

FactoryBot.define do
  factory :task_user do
    task
    association :user, factory: :oauth_user
    scope 'creator'
  end
end
