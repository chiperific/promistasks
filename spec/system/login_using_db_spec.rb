# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Login using db', type: :system, js: true do
  context 'when current_user' do
    before :each do
      user = create(:user)
      login_as(user, scope: :user)
      visit new_user_session_path
    end

    it 'redirects away and flashes a message' do
      expect(current_path).not_to eq new_user_session_path
      expect(page).to have_content 'You are already signed in.'
    end
  end

  context 'when not current_user' do
    it 'displays the login in form' do
      visit new_user_session_path
      expect(page).to have_content 'Log in'
      expect(page).to have_css 'input#user_email'
      expect(page).to have_css 'input#user_password'
    end
  end

  context 'when user credentials are correct' do
    before :each do
      user = create(:user)
      visit new_user_session_path
      fill_in 'user_email', with: user.email
      fill_in 'user_password', with: 'password'
    end

    it 'logs in the user and redirects away' do
      click_submit
      expect(page).to have_content 'Signed in successfully.'
      expect(current_path).not_to eq new_user_session_path
    end
  end

  context 'when user credentials are wrong' do
    before :each do
      visit new_user_session_path
      fill_in 'user_email', with: 'badbad'
      fill_in 'user_password', with: 'badbad'
    end

    it 'displays an error' do
      click_submit
      expect(page).to have_content 'Invalid Email or Password'
      expect(current_path).to eq new_user_session_path
    end
  end
end
