# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Public Page', type: :system do
  context 'when not logged in' do
    pending 'can be visited'
    pending 'shows publicly visited tasks'
    pending 'allows for login'
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
