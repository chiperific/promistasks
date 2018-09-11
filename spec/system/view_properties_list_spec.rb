# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View properties list', type: :system do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit list_properties_path
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit list_properties_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq list_properties_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit list_properties_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq list_properties_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit list_properties_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq list_properties_path
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit list_properties_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Properties'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit list_properties_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Properties'
      end
    end
  end

  context 'when properties are present' do
    before :each do
      @user = create(:admin)
      login_as(@user, scope: :user)
      create(:property, creator: @user) # Yours
      over_budget    = create(:property, budget_cents: 100, creator: @user) # over budget
      nearing_budget = create(:property, budget_cents: 900, creator: @user) # nearing budget
      create(:task, creator: @user, owner: @user) # Have your tasks
      create(:task, property: over_budget, cost_cents: 900)
      create(:task, property: nearing_budget, cost_cents: 200)
      visit list_properties_path
    end

    it 'can show filtered property records' do
      expect(page).to have_css('tbody#property_table_body tr', count: Property.except_default.related_to(@user).count)

      click_link 'Have Your Tasks'
      expect(page).to have_css('tbody#property_table_body tr', count: Property.except_default.with_tasks_for(@user).count)

      click_link 'Missing title'
      expect(page).to have_css('tbody#property_table_body tr', count: Property.except_default.related_to(@user).needs_title.count)

      click_link 'properties_admin'
      expect(page).to have_css('tbody#property_table_body tr', count: Property.except_default.visible_to(@user).count)

      click_link 'Over budget'
      expect(page).to have_css('tbody#property_table_body tr', count: Property.except_default.related_to(@user).over_budget.length)

      click_link 'Nearing budget'
      expect(page).to have_css('tbody#property_table_body tr', count: Property.except_default.related_to(@user).nearing_budget.length)
    end
  end

  context 'when properties are not present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit list_properties_path
    end
    it 'shows the empty partial' do
      visit list_properties_path
      expect(page).to have_content 'It\'s pretty empty in here'
    end
  end
end
