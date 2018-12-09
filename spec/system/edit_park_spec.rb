# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit park', type: :system do
  before :each do
    @park = create(:park)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit edit_park_path(@park)
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit edit_park_path(@park)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_park_path(@park)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit edit_park_path(@park)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_park_path(@park)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit edit_park_path(@park)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_park_path(@park)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit edit_park_path(@park)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Park'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit edit_park_path(@park)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Park'
      end
    end
  end

  context 'when fields' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      @park = create(:park)
      visit edit_park_path(@park)
    end

    context 'have no errors' do
      before :each do
        fill_in 'park_name', with: 'Capybara Park'
      end

      it 'updates the park' do
        click_submit

        expect(page).to have_css 'div#public_tasks'

        expect(@park.reload.name).to eq 'Capybara Park'
      end
    end

    context 'have errors' do
      before :each do
        fill_in 'park_name', with: ''
      end

      it 'shows errors' do
        click_submit

        expect(page).to have_content '1 error found:'
        expect(page).to have_content 'Name can\'t be blank'
      end
    end
  end
end
