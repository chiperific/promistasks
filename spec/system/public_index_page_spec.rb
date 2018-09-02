# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tasks#Public_index Page', type: :system do
  before :each do
    visit root_path
  end

  it 'has certain elements' do
    expect(page).to have_css('div#public_tasks')
    expect(page).to have_css('div#contact_div')
  end

  context 'when organization.volunteer_contact is present' do
    it 'uses volunteer_contact information' do
      user = create(:user)
      Organization.first.update(volunteer_contact: user)
      visit current_path

      expect(page).to have_content("#{user.fname} can help!")
    end
  end

  context 'when organization.volunteer_contact is not present' do
    it 'uses default information' do
      expect(page).to have_content('We can help!')
    end
  end

  context 'when no tasks are public' do
    it 'shows a message' do
      expect(page).to have_css('h1#tasks_empty')
    end
  end

  context 'when public tasks exist' do
    it 'shows a message' do
      create(:task, visibility: 1)
      visit current_path

      expect(page).to have_css('h1#tasks_exist')
    end
  end
end
