# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Logout', type: :system, js: true do
  context 'when not current_user' do
    before :each do
      visit root_path
      visit destroy_user_session_path
    end

    it 'redirects away and flashes a message' do
      expect(current_path).not_to eq destroy_user_session_path
      expect(page).to have_content 'Signed out successfully.'
    end
  end

  context 'when current_user' do
    before :each do
      @user = create(:user)
      login_as(@user, scope: :user)
      visit root_path
    end

    it 'logs out the user and displays a confirmation message' do
      expect(@user.current_sign_in_at).not_to eq nil

      visit destroy_user_session_path

      expect(page).to have_content 'Signed out successfully.'

      @user.reload
      expect(@user.current_sign_in_at).to eq nil
    end
  end
end
