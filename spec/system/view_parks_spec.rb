# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View parks', type: :system do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit parks_path
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when current_user' do
    context 'is anyone' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit parks_path
      end

      pending 'loads the page'
    end

    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit parks_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq parks_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit parks_path
      end

      pending 'loads the page'
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit parks_path
      end

      pending 'loads the page'
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit parks_path
      end

      pending 'loads the page'
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit parks_path
      end

      pending 'loads the page'
    end
  end

  context 'when parks are present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      3.times { create(:park) }
      visit parks_path
    end

    pending 'shows the parks'
  end

  context 'when parks are not present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit parks_path
    end

    it 'shows the empty partial' do
      expect(page).to have_content 'It\'s pretty empty in here'
    end
  end
end
