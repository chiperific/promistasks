# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create new utility', type: :system do
  before :each do
    @utility = create(:utility)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit edit_utility_path(@utility)
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when current_user' do

    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit edit_utility_path(@utility)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_utility_path(@utility)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit edit_utility_path(@utility)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_utility_path(@utility)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit edit_utility_path(@utility)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_utility_path(@utility)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit edit_utility_path(@utility)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Utility'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit edit_utility_path(@utility)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Utility'
      end
    end
  end

  context 'when fields' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit edit_utility_path(@utility)
    end

    context 'have no errors' do
      before :each do
        fill_in 'utility_name', with: 'Capybara Provider'
      end

      it 'updates the utility' do
        click_submit

        expect(page).to have_css 'div#public_tasks'

        expect(@utility.reload.name).to eq 'Capybara Provider'
      end
    end

    context 'have errors' do
      before :each do
        fill_in 'utility_name', with: ''
      end

      it 'shows errors' do
        click_submit

        expect(page).to have_content '1 error found:'
        expect(page).to have_content 'Name can\'t be blank'
      end
    end
  end
end
