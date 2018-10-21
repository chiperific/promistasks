# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit user', type: :system do
  before :each do
    visit root_path
    @user = create(:client_user)
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit edit_user_path(@user)
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when current_user' do
    context 'matches record' do
      before :each do
        login_as(@user, scope: :user)
        visit edit_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit your profile'
      end

      fit 'accepts changes' do
        fill_in 'Name', with: 'Gary Oldman'

        click_submit

        expect(current_path).not_to eq edit_user_path(@user)
        expect(@user.reload.name).to eq 'Gary Oldman'
      end
    end

    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit edit_user_path(@user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_user_path(@user)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit edit_user_path(@user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_user_path(@user)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit edit_user_path(@user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_user_path(@user)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit edit_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content "Edit #{@user.name}'s profile"
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit edit_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content "Edit #{@user.name}'s profile"
      end
    end
  end

  context 'when editing the record' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit edit_user_path(@user)

      @new_user = build(:volunteer_user)

      fill_in 'Name', with: @new_user.name
      fill_in 'user_email', with: @new_user.email
      fill_in 'user_password', with: @new_user.password
      fill_in 'user_password_confirmation', with: @new_user.password
      fill_in 'user_phone', with: @new_user.phone
      fill_in 'user_title', with: 'Grand Champion'
      select 'Volunteer', from: 'user_register_as'

      # when materialize.js is loaded
      # find('input.select-dropdown').click
      # find('li', text: 'Volunteer').click
    end

    context 'with good info' do
      it 'navigates away' do
        click_submit

        expect(current_path).not_to eq edit_user_path(@user)
      end

      it 'updates the record' do
        click_submit

        @user.reload

        expect(@user.name).to eq @new_user.name
      end
    end

    context 'with bad info' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit edit_user_path(@user)

        fill_in 'Name', with: '' # blank
        fill_in 'user_email', with: user.email # non-unique
        fill_in 'user_title', with: 'Grand Champion'
      end

      it 'lists the errors' do
        click_submit

        expect(page).to have_content '2 errors found:'
        expect(page).to have_content 'Name can\'t be blank'
        expect(page).to have_content 'Email has already been taken'
      end
    end
  end

  context 'when record is not present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit edit_user_path(999999)
    end

    it 'redirects away' do
      expect(current_path).not_to eq edit_user_path(@user)
    end
  end
end
