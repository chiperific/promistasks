# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View properties', type: :system, js: true do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit properties_path
      expect(current_path).to eq new_user_session_path
      expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit properties_path
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq properties_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit properties_path
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq properties_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit properties_path
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq properties_path
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit properties_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Properties'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit properties_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Properties'
      end
    end
  end

  context 'when properties are present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      3.times { create(:property) }
      create(:property, is_default: true)
      create(:property, is_private: true)
      visit properties_path
    end

    it 'shows page elements' do
      expect(page).to have_css 'a#list_properties_link'
      expect(page).to have_css 'a#new_property_link'
    end

    it 'shows non-default, non-private properties' do
      expect(Property.count).to eq 5
      expect(page).to have_css 'div.property', count: 3
    end
  end

  context 'when properties are not present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit properties_path
    end
    it 'shows the empty partial' do
      visit properties_path
      expect(page).to have_content 'It\'s pretty empty in here'
    end
  end
end
