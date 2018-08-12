# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    staff true
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "user#{n}@email.computer" }
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

  factory :oauth_user, class: User do
    sequence(:name) { |n| "OAuth User #{n}" }
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "oauth#{n}@email.computer" }
    staff true
    oauth_provider 'google_oauth2'
    sequence(:oauth_id) { |n| "10024006334546302578#{n}" }
    sequence(:oauth_token) { |n| "ya29.FAKEBQqzG5Q8sp3C5T-u1zaedo-jks4rRuPt6oIwqYWONG876pC1MQwOn_rVGUnLFWFpbmcOYmAJMgRC3xzyea2RvQR2W2l-KYQup4A_JvWQsCpmW5RIMFeZ9WO#{n}" }
    oauth_refresh_token '1/FAKEtDf3Qdk9lsbCyTM7AyTHe2PlS_tKqoMlvVsGByk'
    oauth_expires_at Time.now + 24.hours
  end

  factory :admin, class: User do
    sequence(:name) { |n| "System Admin #{n}" }
    admin true
    sequence(:oauth_id) { |n| "10024006334546302578#{n}" }
    password 'password'
    password_confirmation 'password'
    sequence(:email) { |n| "user#{n}@email.computer" }
  end
end
