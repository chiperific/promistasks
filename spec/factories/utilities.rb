# frozen_string_literal: true

FactoryBot.define do
  sequence :utility_name do |n|
    "Necessary Utility Services #{n}"
  end

  sequence :utility_address do |n|
    "333#{n} Corporate Blvd"
  end

  sequence :poc_name do
    call = %w[chad gary buster dawson thor thorson]

    "#{call.sample.capitalize} Representative"
  end

  factory :utility do
    name { generate(:utility_name) }
    address { generate(:utility_address) }
    city { "Walla Walla" }
    state { "WA" }
    postal_code { "99362" }
    poc_name { generate(:poc_name) }
  end
end
