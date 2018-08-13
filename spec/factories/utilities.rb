# frozen_string_literal: true

FactoryBot.define do
  factory :utility do
    sequence(:name) { |n| "Necessary Utility Services #{n}" }
  end
end
