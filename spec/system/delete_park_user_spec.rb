# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Delete park user', type: :system do
  before :each do
    @user = create(:user)
    @park = create(:park)
    @park_user = create(:park_user, user: @user, park: @park)
    login_as(@user, scope: :user)
    visit root_path
  end

  context 'can be done from' do
    it 'User#show' do
      visit user_path(@user)

      expect(page).to have_css 'a.delete_park_user_link'
    end

    it 'Park#show' do
      visit park_path(@park)

      expect(page).to have_css 'a.delete_park_user_link'
    end
  end

  it 'records from User#show' do
    expect { ParkUser.find(@park_user.id) }.not_to raise_error

    visit user_path(@user)

    find('a.delete_park_user_link').click

    expect { ParkUser.find(@park_user.id) }.to raise_error ActiveRecord::RecordNotFound
  end

  it 'records from User#show' do
    expect { ParkUser.find(@park_user.id) }.not_to raise_error

    visit park_path(@park)

    find('a.delete_park_user_link').click

    expect { ParkUser.find(@park_user.id) }.to raise_error ActiveRecord::RecordNotFound
  end
end
