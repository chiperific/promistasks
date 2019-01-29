# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show user tasks finder', type: :system do
  before :each do
    @user = create(:user)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit tasks_finder_user_path(@user)
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit tasks_finder_user_path(@user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq tasks_finder_user_path(@user)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit tasks_finder_user_path(@user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq tasks_finder_user_path(@user)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit tasks_finder_user_path(@user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq tasks_finder_user_path(@user)
      end
    end

    context 'is self' do
      before :each do
        login_as(@user, scope: :user)
        visit tasks_finder_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content "Tasks that match your skills"
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit tasks_finder_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content "Tasks that match #{@user.fname}'s skills"
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit tasks_finder_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content "Tasks that match #{@user.fname}'s skills"
      end
    end
  end

  context 'when tasks match the user\'s skills' do
    before :each do
      @skill = create(:skill)
      @user.skills << @skill

      user = create(:admin)
      login_as(user, scope: :user)

      3.times do
        task = create(:task, visibility: 1)
        task.skills << @skill
      end
      visit tasks_finder_user_path(@user)
    end

    it 'shows the tasks' do
      expect(page).to have_css('tbody#task_table_body tr', count: 3)
    end
  end

  context 'when no tasks match the user\'s skills' do
    before :each do
      @skill = create(:skill)
      @user.skills << @skill

      user = create(:admin)
      login_as(user, scope: :user)

      3.times { create(:task) }
      visit tasks_finder_user_path(@user)
    end

    it 'shows the empty table' do
      expect(page).to have_content 'No tasks'
    end
  end
end
