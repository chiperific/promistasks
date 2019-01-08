# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create payment', type: :system do
  before :each do
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit new_payment_path
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit new_payment_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_payment_path
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit new_payment_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_payment_path
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit new_payment_path
      end

      it 'redirects away' do
        expect(current_path).not_to eq new_payment_path
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit new_payment_path
      end

      it 'loads the page' do
        expect(page).to have_content 'New Payment'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit new_payment_path
      end

      it 'loads the page' do
        expect(page).to have_content 'New Payment'
      end
    end
  end

  context 'when fields' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      @utility = create(:utility)
      @property = create(:property)
      @payment = build(:payment, utility: @utility, property: @property)
      visit new_payment_path
    end

    context 'have no errors' do
      it 'creates a payment' do
        first_count = Payment.count

        find('#payment_paid_to', visible: false).set(@payment.paid_to)
        find('#payment_on_behalf_of', visible: false).set(@payment.on_behalf_of)

        find('#payment_utility_id').select @utility.name
        find('#payment_property_id').select @property.name

        fill_in 'Bill $', with: 45
        fill_in 'Received on', with: Date.today.strftime('%b %d, %y')
        fill_in 'Due on', with: (Date.today + 5.days).strftime('%b %d, %y')
        select 'water', from: 'Type'

        click_submit

        expect(current_path).not_to eq new_payment_path
        expect(Payment.count).to eq first_count + 1
      end
    end

    context 'have errors' do
      fit 'shows errors' do
        click_submit

        expect(page).to have_content '2 errors found:'
      end
    end
  end
end
