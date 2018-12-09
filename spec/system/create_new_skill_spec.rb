# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create new skill', type: :system do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit new_skill_path
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit new_skill_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_skill_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit new_skill_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_skill_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit new_skill_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_skill_path
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit new_skill_path
      end

      it 'loads the page' do
        expect(page).to have_content 'New Skill'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit new_skill_path
      end

      it 'loads the page' do
        expect(page).to have_content 'New Skill'
      end
    end
  end

  context 'when fields' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit new_skill_path
    end

    context 'have no errors' do
      before :each do
        fill_in 'Name', with: 'The agility of the Capybara'
      end

      it 'creates a skill' do
        first_count = Skill.count

        click_submit

        expect(current_path).not_to eq new_skill_path
        expect(Skill.count).to eq first_count + 1

        expect(Skill.last.name).to eq 'The agility of the Capybara'
      end
    end

    context 'have errors' do
      it 'shows errors' do
        click_submit

        expect(page).to have_content '1 error found:'
        expect(page).to have_content 'Name can\'t be blank'
      end
    end
  end
end
