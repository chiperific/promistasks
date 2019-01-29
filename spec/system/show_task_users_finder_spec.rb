# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show task users finder', type: :system do
  before :each do
    @task = create(:task)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit users_finder_task_path(@task)
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit users_finder_task_path(@task)
      end

      it 'redirects away' do
        expect(current_path).not_to eq users_finder_task_path(@task)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit users_finder_task_path(@task)
      end

      it 'redirects away' do
        expect(current_path).not_to eq users_finder_task_path(@task)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit users_finder_task_path(@task)
      end

      it 'redirects away' do
        expect(current_path).not_to eq users_finder_task_path(@task)
      end
    end

    context 'is related to the task' do
      before :each do
        user = @task.creator
        login_as(user, scope: :user)
        visit users_finder_task_path(@task)
      end

      it 'loads the page' do
        expect(page).to have_content 'People with skills that match task:'
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit users_finder_task_path(@task)
      end

      it 'loads the page' do
        expect(page).to have_content 'People with skills that match task:'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit users_finder_task_path(@task)
      end

      it 'loads the page' do
        expect(page).to have_content 'People with skills that match task:'
      end
    end
  end

  context 'when users match the task\'s skills' do
    before :each do
      @skill = create(:skill)
      @task.skills << @skill

      user = create(:admin)
      login_as(user, scope: :user)

      3.times do
        user = create(:user)
        user.skills << @skill
      end
      visit users_finder_task_path(@task)
    end

    it 'shows the users' do
      expect(page).to have_css('tbody#user_table_body tr', count: 3)
    end
  end

  context 'when no users match the task\'s skills' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit users_finder_task_path(@task)
    end

    it 'shows the empty partial' do
      expect(page).to have_content 'No one found'
    end
  end
end
