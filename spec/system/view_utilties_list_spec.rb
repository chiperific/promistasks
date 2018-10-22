# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View utilties list', type: :system do
  before :each do
    3.times do
      create(:utility)
    end
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit utilities_path
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit utilities_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq utilities_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit utilities_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq utilities_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit utilities_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq utilities_path
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit utilities_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Utilities'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit utilities_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Utilities'
      end
    end
  end

  context 'when #records are present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit utilities_path
    end

    it 'shows the #records' do
      expect(page).to have_css('tr.utility-row', count: 3)
    end
  end

  context 'when #records are not present' do
    before :each do
      Utility.destroy_all
      user = create(:admin)
      login_as(user, scope: :user)
      visit utilities_path
    end

    it 'shows the empty partial' do
      expect(page).to have_content 'It\'s pretty empty in here'
    end
  end
end
