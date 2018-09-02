# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sidebar', type: :system do
  context 'when no current_user' do
    before :each do
      visit root_path
    end

    it 'the sidebar is not loaded' do
      expect(page).to have_no_css('ul#slide-out')
    end

    it 'the sidebar button is not loaded' do
      expect(page).to have_no_css('a#sidenav')
    end
  end

  context 'when current_user' do
    context 'is anyone' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit root_path
      end

      it 'the sidebar is loaded' do
        expect(page).to have_css('ul#slide-out')
      end

      it 'the sidebar button is loaded' do
        expect(page).to have_css('a#sidenav')
      end

      it 'has a link to the profile' do
        expect(page).to have_css('a#sidebar_link_profile')
      end

      it 'has a link to current_user\'s tasks' do
        expect(page).to have_css('a#sidebar_link_my_tasks')
      end
    end

    context 'is staff' do
      before :each do
        @user = create(:user)
        login_as(@user, scope: :user)
        visit root_path
      end

      context 'without a default property' do
        it 'doesn\'t show a link to the default tasklist' do
          expect(page).to have_no_css('a#sidebar_link_default')
        end
      end

      context 'with a default property' do
        it 'shows a link to the default tasklist' do
          create(:property, is_default: true, creator: @user)
          visit current_path

          expect(page).to have_css('a#sidebar_link_default')
        end
      end

      it 'has a link to tasks' do
        expect(page).to have_css('a#sidebar_link_tasks')
      end

      it 'has a link to payments' do
        expect(page).to have_css('a#sidebar_link_payments')
      end

      it 'has a link to properties' do
        expect(page).to have_css('a#sidebar_link_properties')
      end

      it 'has a link to parks' do
        expect(page).to have_css('a#sidebar_link_parks')
      end

      it 'has a link to utilities' do
        expect(page).to have_css('a#sidebar_link_utilities')
      end

      it 'has a link to reports' do
        expect(page).to have_css('a#sidebar_link_reports')
      end

      it 'has a link to public tasks' do
        expect(page).to have_css('a#sidebar_link_root')
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit root_path
      end

      it 'has staff links' do
        expect(page).to have_css('a#sidebar_link_tasks')
        expect(page).to have_css('a#sidebar_link_payments')
        expect(page).to have_css('a#sidebar_link_properties')
        expect(page).to have_css('a#sidebar_link_parks')
        expect(page).to have_css('a#sidebar_link_utilities')
        expect(page).to have_css('a#sidebar_link_utilities')
        expect(page).to have_css('a#sidebar_link_reports')
        expect(page).to have_css('a#sidebar_link_root')
      end

      it 'has a link to users' do
        expect(page).to have_css('a#sidebar_link_users')
      end

      it 'has a link to connections' do
        expect(page).to have_css('a#sidebar_link_connections')
      end

      it 'has a link to skills' do
        expect(page).to have_css('a#sidebar_link_skills')
      end
    end
  end
end
