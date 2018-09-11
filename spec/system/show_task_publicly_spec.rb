# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show task publicly', type: :system do
  before :each do
    @task = create(:task, visibility: 1)
    visit root_path
  end

  context 'when not current_user' do
    it 'loads the page' do
      visit public_task_path(@task)
      expect(page).to have_content "Help #{@task.title.downcase}"
    end
  end

  context 'when current_user' do
    context 'is anyone' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit public_task_path(@task)
      end

      it 'loads the page' do
        expect(page).to have_content "Help #{@task.title.downcase}"
      end
    end
  end

  context 'when task is not present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit public_task_path(99999999)
    end

    it 'redirects away' do
      expect(current_path).to eq root_path
    end
  end
end
