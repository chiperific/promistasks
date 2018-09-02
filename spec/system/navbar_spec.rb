# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Navbar', type: :system do
  it 'shows the title' do
    visit root_path

    expect(page).to have_css('a#logo-container')
  end

  context 'when no current_user' do
    before :each do
      visit root_path
    end

    it 'doesn\'t show the sidebar link' do
      expect(page).to have_no_css('a#sidenav')
    end

    it 'shows the login button' do
      expect(page).to have_css('a#login')
    end

    it 'doesn\'t show the logout button' do
      expect(page).to have_no_css('a#logout')
    end

    it 'doesn\'t show the notification button' do
      expect(page).to have_no_css('a#alert_btn')
    end
  end

  context 'when current user' do
    context 'is anyone' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit root_path
      end

      it 'shows the notification button' do
        expect(page).to have_css('a#alert_btn')
      end

      it 'doesn\'t show the login button' do
        expect(page).to have_no_css('a#login')
      end

      it 'shows the logout button' do
        expect(page).to have_css('a#logout')
      end
    end

    context 'is oauth' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit root_path
      end

      it 'shows the API sync button' do
        expect(page).to have_css('a#refresh_button')
      end
    end

    context 'is not oauth' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit root_path
      end

      it 'doesn\'t show the API sync button' do
        expect(page).to have_no_css('a#refresh_button')
      end
    end
  end
end
