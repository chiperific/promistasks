# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Logout', type: :system, js: true do
  context 'when not current_user' do
    before :each do
      visit root_path
      visit '/users/sign_out'
    end

    it 'redirects away' do
      expect(current_path).not_to eq '/users/sign_out'
    end

    it 'flashes a message' do
      expect(page).to have_content 'Signed out successfully.'
    end
  end

  context 'when current_user' do
    before :each do
      @user = create(:user)
      login_as(@user, scope: :user)
      visit root_path
    end

    it 'logs out the user' do
      expect(@user.current_sign_in_at).not_to eq nil

      visit '/users/sign_out'

      @user.reload
      expect(@user.current_sign_in_at).to eq nil
    end

    it 'displays a confirmation message' do
      visit '/users/sign_out'
      expect(page).to have_content 'Signed out successfully.'
    end
  end
end
