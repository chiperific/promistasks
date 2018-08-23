# frozen_string_literal: true

FactoryBot.define do
  sequence :utility_name do |n|
    "Necessary Utility Services #{n}"
  end

  factory :utility do
    name { generate(:utility_name) }
  end
end
