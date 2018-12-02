# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit task', type: :system do
  before :each do
    @task = create(:task)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit edit_task_path(@task)
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit edit_task_path(@task)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_task_path(@task)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit edit_task_path(@task)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Task'
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit edit_task_path(@task)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Task'
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit edit_task_path(@task)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Task'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit edit_task_path(@task)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Task'
      end
    end
  end

  context 'when form fields' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit edit_task_path(@task)
    end

    context 'have no errors' do
      before :each do
      end

      it 'updates a task' do
        fill_in 'Title', with: 'Buy a Capybara Friend'

        click_submit

        expect(current_path).not_to eq edit_task_path(@task)

        expect(@task.reload.title).to eq 'Buy a Capybara Friend'
      end
    end

    context 'have errors' do
      it 'shows errors' do
        fill_in 'Title', with: ''

        click_submit

        expect(page).to have_content '1 error found:'
        expect(page).to have_content 'Title can\'t be blank'
      end
    end
  end
end
