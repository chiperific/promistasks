# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit park user', type: :system do
  before :each do
    @user = create(:user)
    @park = create(:park)
    @park_user = create(:park_user, park: @park, user: @user)
    visit root_path
  end

  context 'can be accessed from' do
    before :each do
      login_as(@user, scope: :user)
    end

    it 'Park#show' do
      visit park_path(@park)

      expect(page).to have_css 'a.edit_park_user_link'
    end

    it 'User#show' do
      visit user_path(@user)

      expect(page).to have_css 'a.edit_park_user_link'
    end
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit edit_park_user_path(@park_user)
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit edit_park_user_path(@park_user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_park_user_path(@park_user)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit edit_park_user_path(@park_user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_park_user_path(@park_user)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit edit_park_user_path(@park_user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_park_user_path(@park_user)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit edit_park_user_path(@park_user)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Connection'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit edit_park_user_path(@park_user)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Connection'
      end
    end
  end

  context 'when form fields' do
    before :each do
      login_as(@user, scope: :user)
      @new_park = create(:park)
      @new_user = create(:volunteer_user)
      visit edit_park_user_path(@park_user)
    end

    context 'have no errors' do
      it 'updates the record' do

        expect(@park_user.park.id).to eq @park.id
        expect(@park_user.user.id).to eq @user.id

        find('#park_user_park_id', visible: false).set(@new_park.id)
        find('#park_user_user_id', visible: false).set(@new_user.id)
        select 'volunteer', from: 'park_user_relationship'

        click_submit

        expect(current_path).not_to eq new_park_user_path
        expect(@park_user.reload.park.id).to eq @new_park.id
        expect(@park_user.reload.user.id).to eq @new_user.id
      end
    end

    context 'have errors' do
      it 'displays errors' do
        find('#park_user_park_id', visible: false).set(0)
        find('#park_user_user_id', visible: false).set(0)

        click_submit

        expect(page).to have_content '4 errors found:'
      end
    end
  end
end
