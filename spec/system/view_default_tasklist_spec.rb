# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View default tasklist', type: :system, js: true do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit default_properties_path
      expect(current_path).to eq new_user_session_path
      expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    before :each do
      @user = create(:oauth_user)
      login_as(@user, scope: :user)
    end

    context 'has a default tasklist' do
      it 'redirects to property#show' do
        property = create(:property, creator: @user, is_default: true)
        visit default_properties_path

        expect(current_path).to eq property_path(property)
        expect(page).to have_content property.name
        expect(page).to have_css 'img[alt="default tasklist"]'
        expect(page).to have_no_css 'a#show_property_link'
        expect(page).to have_no_css 'a#edit_property_link'
      end
    end

    context 'doesn\'t have a default tasklist' do
      it 'redirects away' do
        visit default_properties_path

        expect(current_path).to eq root_path
        expect(page).to have_content 'No default tasklist found'
      end
    end
  end
end
