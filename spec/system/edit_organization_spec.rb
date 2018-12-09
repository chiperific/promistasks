# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit organization', type: :system do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit edit_organization_path
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit edit_organization_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_organization_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit edit_organization_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_organization_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit edit_organization_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_organization_path
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit edit_organization_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_organization_path
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit edit_organization_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Organization:'
      end
    end
  end

  context 'when fields' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit edit_organization_path
    end

    context 'have errors' do
      it 'shows errors' do
        fill_in 'Name', with: ''
        fill_in 'Web domain', with: ''
        fill_in 'Default phone', with: ''
        fill_in 'Default email', with: ''

        click_submit

        expect(page).to have_content '4 errors found:'
      end
    end

    context 'have no errors' do
      it 'updates the organization' do
        fill_in 'Name', with: 'Capybara Refuge'
        fill_in 'Web domain', with: 'www.capybara-refuge.org'
        fill_in 'Default phone', with: '(616) 555-1212'
        fill_in 'Default email', with: 'capyb@rarefuge.org'

        click_submit

        expect(page).not_to eq edit_organization_path
        org = Organization.first

        expect(org.name).to eq 'Capybara Refuge'
        expect(org.domain).to eq 'www.capybara-refuge.org'
        expect(org.default_phone).to eq '(616) 555-1212'
        expect(org.default_email).to eq 'capyb@rarefuge.org'
      end
    end
  end
end
