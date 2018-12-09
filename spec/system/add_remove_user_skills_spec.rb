# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add & remove user skills', type: :system do
  before :each do
    @user = create(:user)
    3.times { create(:skill) }
    visit root_path
  end

  context 'when not current_user' do
    it 'redirects to login page' do
      visit skills_user_path(@user)
      expect(current_path).to eq new_user_session_path
      # expect(page).to have_content('You need to sign in first')
    end
  end

  context 'when current_user' do
    context 'matches the record' do
      before :each do
        login_as(@user, scope: :user)
        visit skills_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content 'Skills for'
      end
    end

    context 'is client' do
      before :each do
        user = create(:client_user)
        login_as(user, scope: :user)
        visit skills_user_path(@user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq skills_user_path(@user)
      end
    end

    context 'is volunteer' do
      before :each do
        user = create(:volunteer_user)
        login_as(user, scope: :user)
        visit skills_user_path(@user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq skills_user_path(@user)
      end
    end

    context 'is contractor' do
      before :each do
        user = create(:contractor_user)
        login_as(user, scope: :user)
        visit skills_user_path(@user)
      end

      it 'redirects away' do
        expect(current_path).not_to eq skills_user_path(@user)
      end
    end

    context 'is staff' do
      before :each do
        user = create(:user)
        login_as(user, scope: :user)
        visit skills_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content 'Skills for'
      end
    end

    context 'is admin' do
      before :each do
        user = create(:admin)
        login_as(user, scope: :user)
        visit skills_user_path(@user)
      end

      it 'loads the page' do
        expect(page).to have_content 'Skills for'
      end
    end
  end

  context 'using the form' do
    before :each do
      user = create(:admin)
      login_as(user, scope: :user)
      visit skills_user_path(@user)
      @skill_ary = Skill.all.pluck(:id).map { |v| v.to_s }
    end

    context 'to add skills to the user' do
      it 'adds skills to the user' do
        expect(@user.skills.count).to eq 0

        find('#add', visible: false).set(@skill_ary.to_s)
        click_submit

        expect(page).not_to eq skills_user_path(@user)

        @user.reload
        expect(@user.skills.count).to eq Skill.count
      end
    end

    context 'to remove skills from the user' do
      before :each do
        Skill.all.each do |skill|
          @user.skills << skill
        end
        @user.reload
      end

      it 'removes skills from the user' do
        expect(@user.skills.count).to eq Skill.count

        find('#remove', visible: false).set(@skill_ary.to_s)
        click_submit

        expect(page).not_to eq skills_user_path(@user)

        @user.reload
        expect(@user.skills.count).to eq 0
      end
    end
  end
end
