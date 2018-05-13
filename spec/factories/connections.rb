# frozen_string_literal: true

FactoryBot.define do
  factory :connection do
    property
    association :user, factory: :contractor_user
    relationship 'contractor'
  end

  factory :connection_stage, class: Connection do
    property
    association :user, factory: :client_user
    relationship 'tennant'
    stage { Constant::Connection::STAGES.sample }
    stage_date { Date.today }
  end
end
