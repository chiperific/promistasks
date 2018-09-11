# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show user', type: :system do
  before :each do
    @record = create(:user)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit user_path(@record)
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when current_user' do
    context 'views their own profile' do
      before :each do
        login_as(@record, scope: :user)
        visit user_path(@record)
      end

      it 'loads the page' do
        expect(page).to have_content 'Your info'
      end
    end

    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit user_path(@record)
      end

      it 'redirects away' do
        expect(current_path).not_to eq user_path(@record)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit user_path(@record)
      end

      it 'redirects away' do
        expect(current_path).not_to eq user_path(@record)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit user_path(@record)
      end

      it 'redirects away' do
        expect(current_path).not_to eq user_path(@record)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit user_path(@record)
      end

      it 'loads the page' do
        expect(page).to have_content @record.name
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit user_path(@record)
      end

      it 'loads the page' do
        expect(page).to have_content @record.name
        expect(page).to have_css 'a#edit_user_link'
        expect(page).to have_css 'a#show_user_tasks_link'
        expect(page).to have_css 'a#edit_user_skills_link'
        expect(page).to have_css 'a#new_user_connection_link'
      end
    end
  end

  context 'when record is not present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit user_path(99999999999)
    end

    it 'redirects away' do
      expect(current_path).not_to eq user_path(@record)
    end
  end

  context 'when record is client' do
    before :each do
      user = create(:admin)
      client = create(:client_user)
      login_as(user, scope: :user)
      visit user_path(client)
    end

    it 'has an occupancies section' do
      expect(page).to have_content 'Occupancy history'
    end
  end

  context 'when record is staff' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit user_path(@record)
    end

    it 'has link to check oauth credentials' do
      expect(page).to have_css 'a#check_credentials_link'
    end
  end
end
