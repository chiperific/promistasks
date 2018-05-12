# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    program_staff true
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "user#{n}@email.computer" }
  end

  factory :program_user, class: User do
    sequence(:name) { |n| "Program #{n}" }
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "program#{n}@email.computer" }
    program_staff true
  end

  factory :project_user, class: User do
    sequence(:name) { |n| "Project #{n}" }
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "project#{n}@email.computer" }
    project_staff true
  end

  factory :admin_user, class: User do
    sequence(:name) { |n| "Admin #{n}" }
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "admin#{n}@email.computer" }
    admin_staff true
  end

  factory :client_user, class: User do
    sequence(:name) { |n| "Client #{n}" }
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "client#{n}@email.computer" }
    client true
  end

  factory :volunteer_user, class: User do
    sequence(:name) { |n| "Volunteer #{n}" }
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "volunteer#{n}@email.computer" }
    volunteer true
  end

  factory :contractor_user, class: User do
    sequence(:name) { |n| "Contractor #{n}" }
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "contractor#{n}@email.computer" }
    contractor true
  end
end
