# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show own tasks', type: :system, js: true do
  before :each do
    @user = create(:user)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit tasks_user_path(@user)
      expect(current_path).to eq new_user_session_path
      expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'matches record' do
      before :each do
        login_as(@user, scope: :user)
        visit tasks_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content 'My Tasks'
        expect(page).to have_css 'ul[name="tasks"]'
        expect(page).to have_css 'tbody#task_table_body'
        expect(page).to have_css 'a#new_task_link'
      end
    end

    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit tasks_user_path(@user)
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq tasks_user_path(@user)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit tasks_user_path(@user)
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq tasks_user_path(@user)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit tasks_user_path(@user)
      end

      it 'flashes error message' do
        expect(page).to have_content('You do not have permission')
      end

      it 'redirects away' do
        expect(current_path).not_to eq tasks_user_path(@user)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit tasks_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content "#{@user.fname}'s Tasks"
        expect(page).to have_css 'ul[name="tasks"]'
        expect(page).to have_css 'tbody#task_table_body'
        expect(page).to have_css 'a#new_task_link'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit tasks_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content "#{@user.fname}'s Tasks"
        expect(page).to have_css 'ul[name="tasks"]'
        expect(page).to have_css 'tbody#task_table_body'
        expect(page).to have_css 'a#new_task_link'
      end
    end
  end

  context 'when tasks are present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit tasks_user_path(@user)
      6.times { create(:task, creator: @user, owner: @user, due: Date.today + 16.days) }
      5.times { create(:task, creator: @user, owner: @user, due: Date.today - 2.days, created_at: Time.now - 3.days) }
      4.times { create(:task, creator: @user, owner: @user, due: Date.today + 2.days) }
      3.times { create(:task, creator: @user, owner: @user, due: Date.today + 9.days) }
      2.times { create(:task, creator: @user, owner: @user, completed_at: Date.today) }
      1.times { create(:task, creator: @user, owner: @user, discarded_at: Date.today) }
      visit tasks_user_path(@user)
    end

    it 'can show active tasks' do
      expect(page).to have_css('tbody#task_table_body tr', count: Task.in_process.count)
    end

    it 'can show past-due tasks' do
      click_link 'Past Due'
      expect(page).to have_css('tbody#task_table_body tr', count: Task.past_due.count)
    end

    it 'can show tasks due within 7 days' do
      click_link 'Due in 7'
      expect(page).to have_css('tbody#task_table_body tr', count: Task.due_within(7).count)
    end

    it 'can show tasks due within 14 days' do
      click_link 'Due in 14'
      expect(page).to have_css('tbody#task_table_body tr', count: Task.due_within(14).count)
    end

    it 'can show completed tasks' do
      click_link 'Completed'
      expect(page).to have_css('tbody#task_table_body tr', count: Task.complete.count)
    end

    it 'can show tasks missing info' do
      click_link 'Missing Info'
      expect(page).to have_css('tbody#task_table_body tr', count: Task.needs_more_info.count)
    end

    it 'can show all tasks' do
      click_link 'All'
      expect(page).to have_css('tbody#task_table_body tr', count: Task.all.count)
    end

    it 'can show archived tasks' do
      click_link 'Archived'
      expect(page).to have_css('tbody#task_table_body tr', count: Task.discarded.count)
    end
  end

  context 'when tasks are not present' do
    it 'shows the empty partial' do
      user = create(:admin)
      login_as(user, scope: :user)
      visit tasks_user_path(@user)
      expect(page).to have_content 'It\'s pretty empty in here'
    end
  end
end
