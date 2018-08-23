# frozen_string_literal: true

FactoryBot.define do
  factory :park_user do
    park
    user
    relationship 'staff contact'
  end
end
