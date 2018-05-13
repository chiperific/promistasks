# frozen_string_literal: true

FactoryBot.define do
  factory :skill_user do
    skill
    user
  end
end
