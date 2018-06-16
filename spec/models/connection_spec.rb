# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Connection, type: :model do
  before :each do
    stub_request(:any, Constant::Regex::TASKLIST).to_return(
      headers: { 'Content-Type'=> 'application/json' },
      status: 200,
      body: FactoryBot.create(:tasklist_json).marshal_dump.to_json
    )
    @connection      = FactoryBot.build(:connection)
    @no_property     = FactoryBot.build(:connection, property_id: nil)
    @no_user         = FactoryBot.build(:connection, user_id: nil)
    @no_relationship = FactoryBot.build(:connection, relationship: nil)
  end

  describe 'must be valid against the schema' do
    it 'in order to save' do
      expect { @connection.save!(validate: false) }.not_to raise_error
      expect { @no_property.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { @no_user.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { @no_relationship.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end
  end

  describe 'must be valid against model' do
    let(:bad_relationship) { build :connection, relationship: 'its complicated' }
    let(:bad_stage) { build :connection_stage, stage: 'threw a party' }

    it 'in order to save' do
      expect(@connection.save!).to eq true
      expect { @no_property.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @no_user.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @no_relationship.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'validates relationship inclusion' do
      expect { bad_relationship.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'validates stage inclusion' do
      expect { bad_stage.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  it 'can\'t duplicate user and property' do
    @connection.save

    property = @connection.property
    user = @connection.user

    duplicate = FactoryBot.build(:connection, property_id: property.id, user_id: user.id)

    expect { duplicate.save! }.to raise_error ActiveRecord::RecordNotUnique
  end

  describe '#relationship_appropriate_for_stage' do
    let(:good_stage) { build :connection_stage }
    let(:bad_stage) { build :connection_stage, relationship: 'volunteer' }

    it 'requires the stage to be "tennant" before saving' do
      expect(good_stage.save!).to eq true
      expect { bad_stage.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe '#relationship_must_match_user_type' do
    let(:program)    { create :program_user }
    let(:project)    { create :project_user }
    let(:admin)      { create :admin_user }
    let(:volunteer)  { create :volunteer_user }
    let(:contractor) { create :contractor_user }
    let(:client)     { create :client_user }

    let(:good_tennant)    { build :connection, relationship: 'tennant', user: client }
    let(:bad_tennant)     { build :connection, relationship: 'tennant', user: admin }
    let(:good_staff)      { build :connection, relationship: 'staff contact', user: program }
    let(:bad_staff)       { build :connection, relationship: 'staff contact', user: client }
    let(:good_contractor) { build :connection, relationship: 'contractor', user: contractor }
    let(:bad_contractor)  { build :connection, relationship: 'contractor', user: volunteer }
    let(:good_volunteer)  { build :connection, relationship: 'volunteer', user: volunteer }
    let(:bad_volunteer)   { build :connection, relationship: 'volunteer', user: client }

    it 'ensures the user type and relationship are in sync' do
      expect(good_tennant.save!).to eq true
      expect { bad_tennant.save! }.to raise_error ActiveRecord::RecordInvalid

      expect(good_staff.save!).to eq true
      expect { bad_staff.save! }.to raise_error ActiveRecord::RecordInvalid

      expect(good_contractor.save!).to eq true
      expect { bad_contractor.save! }.to raise_error ActiveRecord::RecordInvalid

      expect(good_volunteer.save!).to eq true
      expect { bad_volunteer.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe '#stage_date_and_stage' do
    let(:no_date) { build :connection_stage, stage_date: nil }
    let(:no_stage) { build :connection_stage, stage: nil }

    it 'throws an error if only one is present' do
      expect { no_date.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { no_stage.save! }.to raise_error ActiveRecord::RecordInvalid

      no_date.update(stage_date: Date.today)
      no_stage.update(stage: 'applied')

      expect(no_date.save!).to eq true
      expect(no_stage.save!).to eq true
    end
  end
end
