# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    program_staff true
    password 'password'
    password_confirmation 'password'
  end
end
