# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Footer', type: :system do
  context 'when no current_user' do
    it 'is empty' do
      visit root_path
      expect(page).to have_no_css('a#footer_add_btn')
    end
  end

  context 'when current_user' do
    it 'shows up' do
      user = create(:user)
      login_as(user, scope: :user)
      visit root_path

      expect(page).to have_css('a#footer_add_btn')
      expect(page).to have_css('a#footer_link_task')
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit root_path
      end

      it 'shows staff buttons' do
        expect(page).to have_css('a#footer_link_payment')
        expect(page).to have_css('a#footer_link_property')
        expect(page).to have_css('a#footer_link_park')
        expect(page).to have_css('a#footer_link_utility')
        expect(page).to have_css('a#footer_link_skill')
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit root_path
      end

      it 'shows all buttons' do
        expect(page).to have_css('a#footer_link_payment')
        expect(page).to have_css('a#footer_link_property')
        expect(page).to have_css('a#footer_link_park')
        expect(page).to have_css('a#footer_link_utility')
        expect(page).to have_css('a#footer_link_skill')
        expect(page).to have_css('a#footer_link_user')
      end
    end
  end
end
