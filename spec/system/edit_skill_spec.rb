# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit skill', type: :system do
  before :each do
    @skill = create(:skill)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit edit_skill_path(@skill)
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit edit_skill_path(@skill)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_skill_path(@skill)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit edit_skill_path(@skill)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_skill_path(@skill)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit edit_skill_path(@skill)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_skill_path(@skill)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit edit_skill_path(@skill)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit skill'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit edit_skill_path(@skill)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit skill'
      end
    end
  end

  context 'when fields' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit edit_skill_path(@skill)
    end

    context 'have no errors' do
      it 'updates the skill' do
        fill_in 'Name', with: 'The agility of the Capybara'

        click_submit

        expect(page).not_to eq edit_skill_path(@skill)
        @skill.reload
        expect(@skill.name).to eq 'The agility of the Capybara'
      end
    end

    context 'have errors' do
      it 'shows errors' do
        fill_in 'Name', with: ''

        click_submit

        expect(page).to have_content '1 error found:'
        expect(page).to have_content 'Name can\'t be blank'
      end
    end
  end
end
