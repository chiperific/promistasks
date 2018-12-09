# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create new user', type: :system do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit new_user_path
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit new_user_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_user_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit new_user_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_user_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit new_user_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_user_path
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit new_user_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Add New Person'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit new_user_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Add New Person'
        expect(page).to have_css 'input#user_name'
        expect(page).to have_css 'input#user_email'
        expect(page).to have_css 'input#user_password'
        expect(page).to have_css 'input#user_password_confirmation'
        expect(page).to have_css 'input#user_phone'
        expect(page).to have_css 'input#user_title'
      end
    end
  end

  context 'when form fields are accurate' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit new_user_path
      @user = build(:volunteer_user)
      fill_in 'Name', with: @user.name
      fill_in 'user_email', with: @user.email
      fill_in 'user_password', with: @user.password
      fill_in 'user_password_confirmation', with: @user.password
      fill_in 'user_phone', with: @user.phone
      fill_in 'user_title', with: 'Grand Champion'
      select 'Volunteer', from: 'user_register_as'
    end

    it 'creates a user' do
      first_count = User.count

      click_submit

      expect(User.count).to eq first_count + 1
    end

    it 'redirects away' do
      click_submit

      expect(current_path).not_to eq new_user_path
    end
  end

  context 'when form fields are bad' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit new_user_path
      @user = build(:volunteer_user)
      fill_in 'Name', with: @user.name
      fill_in 'user_email', with: @user.email
      fill_in 'user_password', with: @user.password
      fill_in 'user_password_confirmation', with: @user.password
      fill_in 'user_title', with: 'Grand Champion'
      select 'Volunteer', from: 'user_register_as'

      # when materialize.js is loaded
      # find('input.select-dropdown').click
      # find('li', text: 'Volunteer').click
    end

    it 'lists the errors' do
      click_submit
      expect(page).to have_content '1 error found:'
      expect(page).to have_content 'Phone can\'t be blank'
    end
  end
end
