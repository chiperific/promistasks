# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View tasks', type: :system, js: true do
  context 'when records are present' do
    before :each do
      @staff      = create(:user)
      @admin      = create(:admin)
      @client     = create(:client_user)
      @volunteer  = create(:volunteer_user)
      @contractor = create(:contractor_user)
      default = create(:property, is_default: true)
      create(:task, creator: @staff, owner: @staff)
      create(:task, creator: @admin, owner: @staff)
      create(:task, creator: @volunteer, owner: @contractor)
      create(:task, creator: @staff, owner: @volunteer)
      create(:task, creator: @volunteer, owner: @volunteer)
      create(:task, creator: @staff, owner: @staff, visibility: 1)
      create(:task, creator: @staff, owner: @contractor)
      create(:task, creator: @admin, owner: @admin, property: default)
      visit root_path
    end

    context 'when not current_user' do
      it 'redirects to login page' do
        visit tasks_path
        expect(current_path).to eq new_user_session_path
        expect(page).to have_content('You need to sign in first')
      end
    end

    context 'when current_user' do
      context 'is client' do
        before :each do
          login_as(@client, scope: :user)
          visit tasks_path
        end

        it 'flashes error message' do
          expect(page).to have_content('You do not have permission')
        end

        it 'redirects away' do
          expect(current_path).not_to eq tasks_path
        end
      end

      context 'is volunteer' do
        before :each do
          login_as(@volunteer, scope: :user)
          visit tasks_path
        end

        it 'loads the page' do
          expect(page).to have_content 'Tasks'
        end

        it 'only shows visible_to tasks' do
          expect(page).to have_css '#task_table_body tr', count: Task.except_primary.visible_to(@volunteer).in_process.count
        end
      end

      context 'is contractor' do
        before :each do
          login_as(@contractor, scope: :user)
          visit tasks_path
        end

        it 'loads the page' do
          expect(page).to have_content 'Tasks'
        end

        it 'only shows visible_to tasks' do
          expect(page).to have_css '#task_table_body tr', count: Task.except_primary.visible_to(@contractor).in_process.count
        end
      end

      context 'is staff' do
        before :each do
          login_as(@staff, scope: :user)
          visit tasks_path
        end

        it 'loads the page' do
          expect(page).to have_content 'Tasks'
        end

        it 'only shows visible_to tasks' do
          expect(page).to have_css '#task_table_body tr', count: Task.except_primary.visible_to(@staff).in_process.count
        end
      end

      context 'is admin' do
        before :each do
          login_as(@admin, scope: :user)
          visit tasks_path
        end

        it 'loads the page' do
          expect(page).to have_content 'Tasks'
        end

        it 'only shows visible_to tasks' do
          expect(page).to have_css '#task_table_body tr', count: Task.except_primary.visible_to(@admin).in_process.count
        end
      end
    end
  end

  context 'when tasks are not present' do
    it 'shows the empty partial' do
      admin = create(:admin)
      login_as(admin, scope: :user)
      visit tasks_path
      expect(page).to have_content 'It\'s pretty empty in here'
    end
  end
end
