# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Register new user', type: :system do
  context 'when current_user' do
    before :each do
      user = create(:user)
      login_as(user, scope: :user)
      visit new_user_registration_path
    end

    it 'redirects away' do
      expect(current_path).not_to eq new_user_registration_path
    end
  end

  context 'when the page loads' do
    it 'displays the registration in form' do
      visit new_user_registration_path
      expect(page).to have_content 'Sign up'
      expect(page).to have_css 'input#user_email'
      expect(page).to have_css 'input#user_password'
      expect(page).to have_css 'input#user_password_confirmation'
      expect(page).to have_css 'input#user_phone'
    end
  end

  context 'when the form is filled out' do
    before :each do
      @user = build(:volunteer_user)
      visit new_user_registration_path
      fill_in 'Name', with: @user.name
      fill_in 'Email', with: @user.email
      fill_in 'Phone', with: @user.phone
      fill_in 'user[password]', with: @user.password
      fill_in 'user[password_confirmation]', with: @user.password
      select 'Volunteer', from: 'user_register_as'

      # when materialize.js is loaded
      # find('input.select-dropdown').click
      # find('li', text: 'Volunteer').click
    end

    it 'logs in the user' do
      click_submit

      expect(page).to have_css 'a#sidenav'
      click_link 'sidenav'
      expect(page).to have_css 'a#sidebar_link_profile'
      expect(page).to have_css 'a#sidebar_link_my_tasks'
    end

    it 'creates the user in the db' do
      click_submit
      expect(User.where(email: @user.email).count).to eq 1
    end

    it 'redirects away from the registration page' do
      click_submit

      expect(page).to have_no_content 'Sign up'
      expect(current_path).not_to eq new_user_registration_path
    end

    fit 'sends an email to the organization' do
      ActiveJob::Base.queue_adapter = :test

      click_submit

      expect { RegistrationMailer.new_registration_notification.deliver_later }
        .to have_enqueued_job.on_queue('mailers')
    end
  end
end
