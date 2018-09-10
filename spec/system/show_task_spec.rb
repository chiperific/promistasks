# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show task', type: :system, js: true do
  before :each do
    @user = create(:user)
    @task = create(:task, creator: @user, owner: @user)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit task_path(@task)
      expect(current_path).to eq new_user_session_path
      expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'can see task' do
      before :each do
        login_as(@user, scope: :user)
        visit task_path(@task)
      end

      it 'loads the page' do
        expect(page).to have_content @task.title
        expect(page).to have_content @task.property.name
        expect(page).to have_css 'a#edit_task_link'
        expect(page).to have_css 'a#needs_more_info_link'
        expect(page).to have_css 'a#edit_skills_link'
        expect(page).to have_content 'Skills needed'
        expect(page).to have_content 'Relations:'
      end
    end

    context 'cannot see task' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit task_path(@task)
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq task_path(@task)
      end
    end
  end

  context 'when task is not present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit task_path(9999999)
    end

    it 'flashes error message' do
      expect(page).to have_content('Nothing was found')
    end

    it 'redirects away' do
      expect(current_path).to eq root_path
    end
  end
end
