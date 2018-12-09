# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reassign properties page', type: :system do
  before :each do
    @park = create(:park)
    @user = create(:user)
    3.times { create(:property, park: @park, creator: @user) }
    visit root_path
  end

  context 'can be accessed from' do
    it 'Park#show' do
      login_as(@user, scope: :user)
      visit park_path(@park)

      expect(page).to have_css 'a#reassign_properties_link'
    end
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit reassign_properties_path
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit reassign_properties_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_user_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit reassign_properties_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_user_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit reassign_properties_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_user_path
      end
    end

    context 'is staff' do
      before :each do
        login_as(@user, scope: :user)
        visit reassign_properties_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Reassign Properties'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit reassign_properties_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Reassign Properties'
      end
    end
  end

  context 'when properties are present' do
    it 'shows the properties' do
      login_as(@user, scope: :user)
      visit reassign_properties_path
      expect(page).to have_css('tr.park-row', count: 3)
    end
  end

  context 'when properties are not present' do
    before :each do
      Property.destroy_all
      login_as(@user, scope: :user)
      visit reassign_properties_path
    end

    it 'shows the empty partial' do
      expect(page).to have_content 'It\'s pretty empty in here'
    end
  end
end
