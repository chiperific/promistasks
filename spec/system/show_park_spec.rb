# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show park', type: :system do
  before :each do
    @park = create(:park)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit park_path(@park)
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit park_path(@park)
      end

      it 'redirects away' do
        expect(current_path).not_to eq park_path(@park)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit park_path(@park)
      end

      it 'redirects away' do
        expect(current_path).not_to eq park_path(@park)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit park_path(@park)
      end

      it 'redirects away' do
        expect(current_path).not_to eq park_path(@park)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit park_path(@park)
      end

      it 'loads the page' do
        expect(page).to have_content @park.name
        expect(page).to have_content 'Address'

        expect(page).to have_content 'Properties'
        expect(page).to have_content 'Payments'
        expect(page).to have_content 'Connections'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit park_path(@park)
      end

      it 'loads the page' do
        expect(page).to have_content @park.name
        expect(page).to have_content 'Address'

        expect(page).to have_content 'Properties'
        expect(page).to have_content 'Payments'
        expect(page).to have_content 'Connections'
      end
    end

    context 'created a property in the park' do
      before :each do
        user = create(:volunteer_user)
        @park_vis = create(:park)
        create(:property, park: @park_vis, creator: user)
        login_as(user, scope: :user)
        visit park_path(@park_vis)
      end

      it 'loads the page' do
        expect(page).to have_content @park_vis.name
        expect(page).to have_content 'Address'

        expect(page).to have_content 'Properties'
        expect(page).to have_content 'Payments'
      end
    end

    context 'created task(s) in that park' do
      before :each do
        user = create(:volunteer_user)
        @park_task_c = create(:park)
        property = create(:property, park: @park_task_c)
        create(:task, property: property, creator: user)
        login_as(user, scope: :user)
        visit park_path(@park_task_c)
      end

      it 'loads the page' do
        expect(page).to have_content @park_task_c.name
        expect(page).to have_content 'Address'

        expect(page).to have_content 'Properties'
        expect(page).to have_content 'Payments'
      end
    end

    context 'owns task(s) in that park' do
      before :each do
        user = create(:volunteer_user)
        @park_task_o = create(:park)
        property = create(:property, park: @park_task_o)
        create(:task, property: property, owner: user)
        login_as(user, scope: :user)
        visit park_path(@park_task_o)
      end

      it 'loads the page' do
        expect(page).to have_content @park_task_o.name
        expect(page).to have_content 'Address'

        expect(page).to have_content 'Properties'
        expect(page).to have_content 'Payments'
      end
    end
  end
end
