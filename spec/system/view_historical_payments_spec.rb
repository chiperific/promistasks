# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View historical payments', type: :system do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit history_payments_path
      expect(current_path).to eq new_user_session_path
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit history_payments_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq history_payments_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit history_payments_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq history_payments_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit history_payments_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq history_payments_path
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit history_payments_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Payments'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit history_payments_path
      end

      it 'loads the page' do
        expect(page).to have_content 'Payments'
      end
    end
  end

  context 'when payments are present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      3.times { create(:old_payment) }
      visit history_payments_path
    end

    it 'shows the payments' do
      expect(page).to have_css('tr.payment-row', count: 3)
    end
  end

  context 'when payments are not present' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit history_payments_path
    end

    it 'shows the empty partial' do
      expect(page).to have_content 'It\'s pretty empty in here'
    end
  end
end
