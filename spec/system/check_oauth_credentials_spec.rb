# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Check oauth credentials', type: :system, js: true do
  before :each do
    @staff = create(:user)
    @client = create(:client_user)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit oauth_check_user_path(@staff)
      expect(current_path).to eq new_user_session_path
      expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is record and is staff' do
      before :each do
        login_as(@staff, scope: :user)
        visit oauth_check_user_path(@staff)
      end

      it 'loads the page' do
        expect(page).to have_content 'Credential status:'
      end
    end

    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit oauth_check_user_path(@staff)
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq oauth_check_user_path(@staff)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit oauth_check_user_path(@staff)
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq oauth_check_user_path(@staff)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit oauth_check_user_path(@staff)
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq oauth_check_user_path(@staff)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit oauth_check_user_path(@staff)
      end

      it 'loads the page' do
        expect(page).to have_content 'Credential status:'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit oauth_check_user_path(@staff)
      end

      it 'loads the page' do
        expect(page).to have_content 'Credential status:'
      end
    end
  end

  context 'when record is staff' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit oauth_check_user_path(@staff)
    end

    it 'shows the status of oauth fields' do
      expect(page).to have_content 'Google ID?'
      expect(page).to have_content 'Google Token?'
      expect(page).to have_content 'Google Refresh Token?'
      expect(page).to have_content 'Google Token Expires at:'
    end

    it 'provides instructions for resetting the oauth connection' do
      expect(page).to have_content 'How to reset your credentials:'
    end
  end

  context 'when record is not staff' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit oauth_check_user_path(@client)
    end

    it 'flashes error message' do
      expect(page).to have_content "#{@client.name} has no credentials to check."
    end

    it 'redirects away' do
      expect(current_path).not_to eq oauth_check_user_path(@client)
    end
  end
end
