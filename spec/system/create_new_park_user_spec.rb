# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create new park user', type: :system do
  before :each do
    visit root_path
  end

  context 'can be accessed from' do
    before :each do
      @user = create(:admin)
      login_as(@user, scope: :user)
    end

    it 'Park#show' do
      park = create(:park)
      visit park_path(park)

      expect(page).to have_css 'a#new_park_user_link'
    end

    it 'User#show' do
      visit user_path(@user)

      expect(page).to have_css 'a#new_park_user_link'
    end
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit new_park_user_path
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit new_park_user_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_park_user_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit new_park_user_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_park_user_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit new_park_user_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_park_user_path
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit new_park_user_path
      end

      it 'loads the page' do
        expect(page).to have_content 'New Park User'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit new_park_user_path
      end

      it 'loads the page' do
        expect(page).to have_content 'New Park User'
      end
    end
  end

  context 'when form fields' do
    before :each do
      @user = create(:admin)
      @park = create(:park)
      login_as(@user, scope: :user)
      visit new_park_user_path
    end

    context 'have no errors' do
      it 'creates a new record' do
        first_count = ParkUser.count

        find('#park_user_park_id', visible: false).set(@park.id)
        find('#park_user_user_id', visible: false).set(@user.id)
        select 'staff contact', from: 'park_user_relationship'

        click_submit

        expect(current_path).not_to eq new_park_user_path
        expect(ParkUser.count).to eq first_count + 1
      end
    end

    context 'have errors' do
      it 'displays errors' do
        click_submit

        expect(page).to have_content '6 errors found:'
      end
    end
  end
end
