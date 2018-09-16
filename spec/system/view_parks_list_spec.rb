# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View parks list', type: :system do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit list_parks_path
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit list_parks_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq list_parks_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit list_parks_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq list_parks_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit list_parks_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq list_parks_path
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit list_parks_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Parks'
        expect(page).to have_css 'a#parks_link'
        expect(page).to have_css 'a#new_park_link'
        expect(page).to have_css 'a#parks_active'
        expect(page).to have_css 'a#parks_archived'
        expect(page).to have_css 'tbody#park_table_body'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit list_parks_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Parks'
        expect(page).to have_css 'a#parks_link'
        expect(page).to have_css 'a#new_park_link'
        expect(page).to have_css 'tbody#park_table_body'
      end
    end
  end

  context 'when parks are present' do
    before :each do
      @user = create(:admin)
      login_as(@user, scope: :user)
      @user.update(current_sign_in_at: Time.now - 1.hour)
      @user.reload
      3.times { create(:park) }
      visit list_parks_path
    end

    it 'shows the parks' do
      expect(page).to have_css 'tr.park-row', count: Park.count
    end

    it 'has tabs to filter parks' do
      Park.first.update(created_at: Time.now - 1.day)
      Park.last.discard

      expect(page).to have_css 'a#parks_new'
      expect(page).to have_css 'a#parks_active'
      expect(page).to have_css 'a#parks_archived'

      click_link 'New'
      expect(page).to have_css 'tr.park-row', count: Park.created_since(@user.last_sign_in_at).count

      click_link 'Active'
      expect(page).to have_css 'tr.park-row', count: Park.undiscarded.count

      click_link 'Archived'
      expect(page).to have_css 'tr.park-row', count: Park.discarded.count
    end
  end

  context 'when parks are not present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit list_parks_path
    end

    it 'shows the empty partial' do
      expect(page).to have_content 'It\'s pretty empty in here'
    end
  end
end
