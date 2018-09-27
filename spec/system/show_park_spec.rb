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
    context 'is anyone' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit park_path(@park)
      end

      pending 'loads the page'
    end

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

      pending 'loads the page'
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit park_path(@park)
      end

      pending 'loads the page'
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit park_path(@park)
      end

      pending 'loads the page'
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit park_path(@park)
      end

      pending 'loads the page'
    end
  end
end
