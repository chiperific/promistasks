# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit payment', type: :system do
  before :each do
    @payment = create(:payment)
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit edit_payment_path(@payment)
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit edit_payment_path(@payment)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_payment_path(@payment)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit edit_payment_path(@payment)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_payment_path(@payment)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit edit_payment_path(@payment)
      end

      it 'redirects away' do
        expect(current_path).not_to eq edit_payment_path(@payment)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit edit_payment_path(@payment)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Payment'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit edit_payment_path(@payment)
      end

      it 'loads the page' do
        expect(page).to have_content 'Edit Payment'
      end
    end
  end

  context 'when fields' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      @new_utility = create(:utility)
      @new_property = create(:property)
      @new_payment = build(:payment, utility: @new_utility, property: @new_property)
      visit edit_payment_path(@payment)
    end

    context 'have no errors' do
      it 'updates the payment' do
        find('#payment_utility_id').select @new_utility.name
        find('#payment_property_id').select @new_property.name
        select 'sewer', from: 'Type'

        click_submit

        expect(current_path).not_to eq new_payment_path
        @payment.reload
        expect(@payment.utility.name).to eq @new_utility.name
        expect(@payment.property.name).to eq @new_property.name
        expect(@payment.utility_type).to eq 'sewer'
      end
    end

    context 'have errors' do
      fit 'shows errors' do
        fill_in 'Bill $', with: nil
        click_submit

        expect(page).to have_content '1 error found:'
      end
    end
  end
end
