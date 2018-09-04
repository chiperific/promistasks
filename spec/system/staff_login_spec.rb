# frozen_string_literal: true

require 'rails_helper'

OmniAuth.config.test_mode = true
raw_auth = JSON.parse(File.read(Rails.root.to_s + '/spec/fixtures/auth_spec.json'))
OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(raw_auth)

RSpec.describe 'Staff Login', type: :system do
  before :each do
    # Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
    # Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
    visit new_user_session_path
  end

  context 'when the page loads' do
    it 'displays the Staff Sign In button' do
      expect(page).to have_content 'Log in'
      expect(page).to have_content 'Staff Sign In'
    end
  end

  context 'when the button is pushed' do
    it 'creates and signs in a user' do
      click_link('Staff Sign In')

      visit '/users/auth/google_oauth2/callback'

      expect(page).to have_css('a#logout')
      expect(User.where(email: 'someperson@gmail.com').count).to eq 1
    end
  end
end
