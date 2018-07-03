# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tasks#Public Page', type: :system do
  context 'when not logged in' do
    it 'can be visited' do
      visit '/'

      expect(page).to have_content ''
    end
    pending 'shows publicly visited tasks'
    pending 'allows for login'
    pending 'doesn\'t show the sidenav'
    pending 'doesn\'t show the sync button'
  end

  context 'when logged in' do
    context 'as a staff member' do
      pending 'redirects to Properties#index'
    end

    context 'as an exteral user' do
      pending 'can be visited'
      pending 'shows related properties and tasks'
    end

    context 'as a system admin' do
      pending 'redirects to Properties#index'
      # move this to properties#index spec:
      # pending 'shows "manage users" link'
    end
  end
end
