# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    park
    bill_amt 400
    received Date.today
    due Date.today + 15.days
    association :creator, factory: :user
  end

  factory :payment_property, class: Payment do
    property
    bill_amt 400
    received Date.today
    due Date.today + 15.days
    association :creator, factory: :user
  end

  factory :payment_utility, class: Payment do
    utility
    bill_amt 400
    received Date.today
    due Date.today + 15.days
    association :creator, factory: :user
  end

  factory :payment_task, class: Payment do
    task
    bill_amt 400
    received Date.today
    due Date.today + 15.days
    association :creator, factory: :user
  end

  factory :payment_contractor, class: Payment do
    association :contractor, factory: :contractor_user
    bill_amt 400
    received Date.today
    due Date.today + 15.days
    association :creator, factory: :user
  end

  factory :payment_client, class: Payment do
    association :client, factory: :client_user
    bill_amt 400
    received Date.today
    due Date.today + 15.days
    association :creator, factory: :user
  end
end
