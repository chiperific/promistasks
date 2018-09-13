# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit property', type: :system do
  before :each do
    @creator = create(:user)
    @property = create(:property, creator: @creator)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit edit_property_path(@property)
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when current_user' do
    context 'created the record' do
      before :each do
        login_as(@creator, scope: :user)
        visit edit_property_path(@property)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Property'
      end
    end

    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit edit_property_path(@property)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_property_path(@property)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit edit_property_path(@property)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_property_path(@property)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit edit_property_path(@property)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_property_path(@property)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit edit_property_path(@property)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Property'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit edit_property_path(@property)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Property'
      end
    end
  end

  context 'when fields' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      @property = create(:property)
      visit edit_property_path(@property)
    end

    context 'have no errors' do
      before :each do
        fill_in 'property_name', with: 'Capybara Place'
        fill_in 'property_address', with: '123 Main St'
        fill_in 'property_city', with: 'Stockholm'
        fill_in 'property_state', with: 'Sweden'
      end

      it 'updates the property' do
        click_submit

        expect(page).to have_css 'div#public_tasks'

        expect(@property.reload.name).to eq 'Capybara Place'
      end

      it 'redirects away' do
        click_submit

        expect(current_path).not_to eq new_property_path
      end
    end
  end

  context 'when property is not present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit edit_property_path(99999)
    end

    it 'redirects away' do
      expect(current_path).not_to eq edit_property_path(@property)
    end
  end
end
