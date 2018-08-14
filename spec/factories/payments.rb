# frozen_string_literal: true

FactoryBot.define do
  factory :payment_property, class: Payment do
    property
    bill_amt 400
    received Date.today
    due Date.today + 15.days
    association :creator, factory: :user
  end

  factory :payment_park, class: Payment do
    park
    bill_amt 400
    received Date.today
    due Date.today + 15.days
    association :creator, factory: :user
  end
end
