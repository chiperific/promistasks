# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View user list', type: :system, js: true do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit users_path
      expect(current_path).to eq new_user_session_path
      expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit users_path
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq users_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit users_path
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq users_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit users_path
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq users_path
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit users_path
      end

      it 'loads the page' do
        expect(page).to have_content 'People'
        expect(page).to have_css 'ul[name="users"]'
        expect(page).to have_css 'tbody#user_table_body'
        expect(page).to have_css 'a#new_user_link'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit users_path
      end

      it 'loads the page' do
        expect(page).to have_content 'People'
        expect(page).to have_css 'ul[name="users"]'
        expect(page).to have_css 'tbody#user_table_body'
        expect(page).to have_css 'a#new_user_link'
      end
    end
  end

  context 'when users are present' do
    before :each do
      3.times { create(:user) }
      admin = create(:admin)
      4.times { create(:client_user) }
      2.times { create(:volunteer_user) }
      create(:contractor_user)
      login_as(admin, scope: :user)
      visit users_path
    end

    it 'can show all user records' do
      expect(page).to have_css('tbody#user_table_body tr', count: User.count)
    end

    it 'can show staff users' do
      click_link 'Staff'
      expect(page).to have_css('tbody#user_table_body tr', count: User.staff.count)
    end

    it 'can show client users' do
      click_link 'Staff'
      expect(page).to have_css('tbody#user_table_body tr', count: User.clients.count)
    end

    it 'can show volunteer users' do
      click_link 'Volunteer'
      expect(page).to have_css('tbody#user_table_body tr', count: User.volunteers.count)
    end

    it 'can show contractor users' do
      click_link 'Contractor'
      expect(page).to have_css('tbody#user_table_body tr', count: User.contractors.count)
    end

    it 'can show admin users' do
      click_link 'Admins'
      expect(page).to have_css('tbody#user_table_body tr', count: User.admins.count)
    end

    it 'can show archived users' do
      User.find([1, 3, 5]).each(&:discard)

      click_link 'Archived'
      expect(page).to have_css('tbody#user_table_body tr', count: User.discarded.count)
    end
  end
end
