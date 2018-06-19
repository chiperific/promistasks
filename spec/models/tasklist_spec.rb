# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tasklist, type: :model do
  before :each do
    @user = FactoryBot.create(:oauth_user)
    @property = FactoryBot.create(:property, creator: @user, is_private: true)
    @tasklist = @property.reload.tasklists.first
    WebMock.reset_executed_requests!
  end

  describe 'must be valid' do
    let(:no_user)         { build :tasklist, user_id: nil }
    let(:no_property)     { build :tasklist, property_id: nil }
    let(:user)            { create :oauth_user }
    let(:property)        { create :property, creator: user, is_private: true }


    it 'in order to save' do
      property.reload.tasklists.first.destroy
      tasklist = FactoryBot.build(:tasklist, property: property, user: user)
      expect(tasklist.save!).to eq true


      expect { no_user.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_property.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_user.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { no_property.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires uniqueness' do
    it 'on user and property' do
      @tasklist.save

      user = @tasklist.user
      property = @tasklist.property

      duplicate = FactoryBot.build(:tasklist, user_id: user.id, property_id: property.id)

      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    context 'on google_id' do
      before :each do
        @tasklist.save
        gid = @tasklist.google_id
        property = @tasklist.property
        property.update(name: 'validate')

        @duplicate = FactoryBot.build(:tasklist, property: property, google_id: gid)
      end

      it 'in the model' do
        expect { @duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'but not in the schema' do
        expect { @duplicate.save!(validate: false) }.not_to raise_error
      end

    end
  end

  describe '#list_api_tasks' do
    before :each do
      @local_user = FactoryBot.create(:user)
      @local_tasklist = FactoryBot.create(:tasklist, user: @local_user)
    end

    it 'returns false for non-oauth users' do
      expect(@local_tasklist.list_api_tasks).to eq false
    end

    it 'calls user.refresh_token!' do
      user = @tasklist.user
      expect(user).to receive(:refresh_token!)
      @tasklist.list_api_tasks
    end

    it 'makes an API call' do
      @tasklist.list_api_tasks
      expect(WebMock).to have_requested(:get, 'https://www.googleapis.com/tasks/v1/lists/' + @tasklist.google_id + '/tasks/')
    end

    it 'returns a list of tasks related to the tasklist' do
      response = @tasklist.list_api_tasks
      expect(response['kind']).to eq 'tasks#tasks'
    end
  end

  describe 'api interactions' do
    before :each do
      @local_user = FactoryBot.create(:user)
      @local_tasklist = FactoryBot.create(:tasklist, user: @local_user)
      WebMock.reset_executed_requests!
    end

    describe '#api_get' do
      it 'returns false if user isn\'t oauth' do
        expect(@local_tasklist.api_get).to eq false
      end

      it 'returns false if google_id is missing' do
        @tasklist.google_id = nil
        expect(@tasklist.api_get).to eq false
      end

      it 'makes an API call' do
        @tasklist.api_get
        expect(WebMock).to have_requested(:get, Constant::Regex::TASKLIST)
      end

      it 'returns the API response' do
        response = @tasklist.api_get
        expect(response['kind']).to eq 'tasks#taskList'
      end
    end

    describe '#api_insert' do
      it 'returns false if user isn\'t oauth' do
        expect(@local_tasklist.api_insert).to eq false
      end

      it 'makes an API call' do
        @tasklist.api_insert
        expect(WebMock).to have_requested(:post, Constant::Regex::TASKLIST)
      end

      it 'returns the API response' do
        response = @tasklist.api_insert
        expect(response['kind']).to eq 'tasks#taskList'
      end
    end

    describe '#api_update' do
      it 'returns false if user isn\'t oauth' do
        expect(@local_tasklist.api_update).to eq false
      end

      it 'returns false if google_id is missing' do
        @tasklist.google_id = nil
        expect(@tasklist.api_update).to eq false
      end

      it 'makes an API call' do
        @tasklist.api_update
        expect(WebMock).to have_requested(:patch, Constant::Regex::TASKLIST)
      end

      it 'returns the API response' do
        response = @tasklist.api_update
        expect(response['kind']).to eq 'tasks#taskList'
      end
    end

    describe '#api_delete' do
      it 'returns false if user isn\'t oauth' do
        expect(@local_tasklist.api_delete).to eq false
      end

      it 'returns false if google_id is missing' do
        @tasklist.google_id = nil
        expect(@tasklist.api_delete).to eq false
      end

      it 'makes an API call' do
        @tasklist.api_delete
        expect(WebMock).to have_requested(:delete, Constant::Regex::TASKLIST)
      end

      it 'returns the API response' do
        response = @tasklist.api_delete
        expect(response['kind']).to eq 'tasks#taskList'
      end
    end
  end

  describe '#api_headers' do
    it 'returns a hash that includes the user\'s oauth_token' do
      response = @tasklist.send(:api_headers)
      expect(response.as_json['Authorization']).to eq 'OAuth ' + @tasklist.user.oauth_token
    end
  end
end
