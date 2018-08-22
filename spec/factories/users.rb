# frozen_string_literal: true

FactoryBot.define do
  sequence :oauth_id do |n|
    "10024006334546302578#{n}"
  end

  sequence :oauth_token do |n|
    "ya29.FAKEBQqzG5Q8sp3C5T-u1zaedo-jks4rRuPt6oIwqYWONG876pC1MQwOn_rVGUnLFWFpbmcOYmAJMgRC3xzyea2RvQR2W2l-KYQup4A_JvWQsCpmW5RIMFeZ9WO#{n}"
  end

  factory :user do
    sequence(:name) { |n| "User #{n}" }
    phone '555-1212'
    staff true
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "user#{n}@email.computer" }
  end

  factory :client_user, class: User do
    sequence(:name) { |n| "Client #{n}" }
    phone '555-1212'
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "client#{n}@email.computer" }
    client true
  end

  factory :volunteer_user, class: User do
    sequence(:name) { |n| "Volunteer #{n}" }
    phone '555-1212'
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "volunteer#{n}@email.computer" }
    volunteer true
  end

  factory :contractor_user, class: User do
    sequence(:name) { |n| "Contractor #{n}" }
    phone '555-1212'
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "contractor#{n}@email.computer" }
    contractor true
  end

  factory :oauth_user, class: User do
    sequence(:name) { |n| "OAuth User #{n}" }
    phone '555-1212'
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "oauth#{n}@email.computer" }
    staff true
    oauth_provider 'google_oauth2'
    oauth_id
    oauth_token
    oauth_refresh_token '1/FAKEtDf3Qdk9lsbCyTM7AyTHe2PlS_tKqoMlvVsGByk'
    oauth_expires_at Time.now + 24.hours
  end

  factory :admin, class: User do
    sequence(:name) { |n| "Admin #{n}" }
    phone '555-1212'
    admin true
    oauth_id
    oauth_token
    oauth_refresh_token '1/FAKEtDf3Qdk9lsbCyTM7AyTHe2PlS_tKqoMlvVsGByk'
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "admin#{n}@email.computer" }
  end
end
