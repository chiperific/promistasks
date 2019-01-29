# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create new task', type: :system do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit new_task_path
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit new_task_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_task_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit new_task_path
      end

      it 'loads the page' do
        expect(page).to have_content 'New Task'
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit new_task_path
      end

      it 'loads the page' do
        expect(page).to have_content 'New Task'
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit new_task_path
      end

      it 'loads the page' do
        expect(page).to have_content 'New Task'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit new_task_path
      end

      it 'loads the page' do
        expect(page).to have_content 'New Task'
      end
    end
  end

  context 'when form fields' do
    before :each do
      @user = create(:admin)
      login_as(@user, scope: :user)
      visit new_task_path
    end

    context 'have no errors' do
      before :each do
        @property = create(:property)
        @property.tasks.destroy_all
      end

      it 'creates a task' do
        first_count = Task.count

        fill_in 'Title', with: 'Buy a Capybara Friend'
        find('#task_owner_id', visible: false).set(@user.id)
        find('#task_property_id', visible: false).set(@property.id)
        select 'low', from: 'Priority'
        select 'Staff', from: 'Visibility'

        click_submit

        expect(current_path).not_to eq new_task_path

        expect(Task.count).to eq first_count + 1

        expect(Task.last.title).to eq 'Buy a Capybara Friend'
      end
    end

    context 'have errors' do
      it 'shows errors' do
        click_submit

        expect(page).to have_content '3 errors found:'
        expect(page).to have_content 'Property must exist'
        expect(page).to have_content 'Title can\'t be blank'
        expect(page).to have_content 'Property can\'t be blank'
      end
    end
  end
end
