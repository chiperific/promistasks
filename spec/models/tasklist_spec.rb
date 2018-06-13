# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tasklist, type: :model do
  before :each do
    stub_request(:any, Constant::Regex::TASKLIST).to_return(
      headers: { 'Content-Type'=> 'application/json' },
      status: 200,
      body: FactoryBot.create(:tasklist_json).marshal_dump.to_json
    )
    stub_request(:any, Constant::Regex::TASK).to_return(
      headers: { 'Content-Type'=> 'application/json' },
      status: 200,
      body: FactoryBot.create(:task_json).marshal_dump.to_json
    )
    @tasklist = FactoryBot.build(:tasklist)
    WebMock::RequestRegistry.instance.reset!
  end

  describe 'must be valid' do
    let(:no_user)         { build :tasklist, user_id: nil }
    let(:no_property)     { build :tasklist, property_id: nil }
    let(:no_google_id)    { build :tasklist, google_id: nil }

    it 'in order to save' do
      expect(@tasklist.save!).to eq true

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

    it 'on google_id' do
      @tasklist.save

      gid = @tasklist.google_id
      property = @tasklist.property
      property.update(name: 'validate')

      duplicate = FactoryBot.build(:tasklist, property: property, google_id: gid)

      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
    end
  end

  describe '#list_api_tasks' do
    pending 'returns false for non-oauth users'
    pending 'calls user.refresh_token!'
    pending 'makes an API call'
    pending 'returns a list of tasks related to the tasklist'
  end
end
