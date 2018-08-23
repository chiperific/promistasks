# frozen_string_literal: true

FactoryBot.define do
  factory :park do
    sequence(:name) { |n| "Factory Meadows #{n}" }
  end
end
