# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show property', type: :system do
  before :each do
    @user = create(:user)
    @property = create(:property, creator: @user)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit property_path(@property)
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when current_user' do
    context 'is related to property' do
      before :each do
        login_as(@user, scope: :user)
        visit property_path(@property)
      end

      it 'loads the page' do
        expect(page).to have_content @property.name
      end
    end

    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit property_path(@property)
      end

      it 'redirects away' do
        expect(current_path).not_to eq property_path(@property)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit property_path(@property)
      end

      it 'redirects away' do
        expect(current_path).not_to eq property_path(@property)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit property_path(@property)
      end

      it 'redirects away' do
        expect(current_path).not_to eq property_path(@property)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit property_path(@property)
      end

      it 'loads the page' do
        expect(page).to have_content @property.name
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit property_path(@property)
      end

      it 'loads the page' do
        expect(page).to have_content @property.name
      end
    end
  end

  context 'when property is present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      3.times { create(:property) }
      visit property_path(@property)
    end

    it 'shows the property and details' do
      expect(page).to have_css 'img.street-map'
      expect(page).to have_css 'a#edit_property_link'
      expect(page).to have_content 'Creator'
      expect(page).to have_content 'Occupancy status'
      expect(page).to have_content 'Lot rent'
      expect(page).to have_content 'Beds'
      expect(page).to have_content 'Baths'
      expect(page).to have_content 'Visibility'
      expect(page).to have_content 'Tasks'
      expect(page).to have_css 'a#new_task_link'
      expect(page).to have_css 'tbody#task_table_body'
      expect(page).to have_content 'Occupancies'
      expect(page).to have_content 'Connections'
      expect(page).to have_content 'More info:'
      expect(page).to have_css 'a#back_btn'
    end
  end

  context 'when property is not present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit property_path(9999999)
    end
    it 'redirects away' do
      expect(current_path).to eq root_path
    end
  end
end
