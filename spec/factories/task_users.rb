# frozen_string_literal: true

FactoryBot.define do
  factory :task_user do
    task
    tasklist_gid { 'FAKEMDQ5NTUwMTk3NjU1MjE3MTU6MDow' }
    association :user, factory: :oauth_user
    scope { 'creator' }
  end
end
