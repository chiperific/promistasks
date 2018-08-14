# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Connection, type: :model do
  before :each do
    @connection = FactoryBot.build(:connection)
  end

  describe 'must be valid' do
    before :each do
      @no_property     = FactoryBot.build(:connection, property_id: nil)
      @no_user         = FactoryBot.build(:connection, user_id: nil)
      @no_relationship = FactoryBot.build(:connection, relationship: nil)
    end

    context 'against the schema' do
      it 'in order to save' do
        expect { @connection.save!(validate: false) }.not_to raise_error
        expect { @no_property.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { @no_user.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { @no_relationship.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      end
    end

    context 'against model' do
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
  end

  describe '#archive_property' do
    let(:archivable)              { build :connection_stage, stage: 'title transferred' }
    let(:wrong_stage)             { build :connection_stage, stage: 'approved' }
    let(:not_archivable_property) { build :connection_stage, stage: 'title transferred' }
    let(:not_archivable_tasks)    { build :connection_stage, stage: 'title transferred' }

    context 'when stage != title transferred' do
      it 'doesn\'t fire' do
        expect(wrong_stage).not_to receive(:archive_property)
        wrong_stage.save
      end
    end

    context 'when stage == title transferred' do
      it 'fires' do
        expect(archivable).to receive(:archive_property).once
        archivable.save
      end

      context 'when property.stage == complete and property has no tasks in_process' do
        it 'discards the parent property' do
          expect(archivable.property.discarded?).to eq false

          archivable.save
          archivable.reload
          expect(archivable.property.discarded?).to eq true
        end
      end

      context 'when property.stage != complete' do
        it 'does not discard the parent property' do
          not_archivable_property.property.update(stage: 'construction')

          expect(not_archivable_property.property.discarded?).to eq false

          not_archivable_property.send(:archive_property)

          expect(not_archivable_property.property.discarded?).to eq false
        end
      end

      context 'when property has tasks in_process' do
        before :each do
          @property = not_archivable_tasks.property
          @task = FactoryBot.create(:task, property: @property)
        end

        it 'does not discard the parent property' do
          expect(not_archivable_tasks.property.tasks.count).to eq 1
          expect(not_archivable_tasks.property.discarded?).to eq false

          not_archivable_tasks.send(:archive_property)

          expect(not_archivable_tasks.property.discarded?).to eq false
        end
      end
    end
  end

  describe '#property_ready_for_tennant' do
    let(:wrong_relationship) { build :connection }
    let(:property_stage_complete) { build :connection_stage }
    let(:property_stage_not_complete) { build :connection_stage }

    it 'doesn\'t fire if relationship != tennant' do
      expect(wrong_relationship).not_to receive(:property_ready_for_tennant)

      wrong_relationship.save
    end

    it 'doesn\'t fire if property.stage == complete' do
      expect(property_stage_complete).not_to receive(:property_ready_for_tennant)

      property_stage_complete.save
    end

    context 'when relationship == tennant and property.stage != complete' do
      before :each do
        property_stage_not_complete.property.update(stage: 'construction')
      end

      it 'fires' do
        expect(property_stage_not_complete).to receive(:property_ready_for_tennant)

        property_stage_not_complete.save
      end

      it 'adds an error to relationship' do
        expect(property_stage_not_complete.valid?).to eq false
        expect(property_stage_not_complete.errors[:relationship].present?).to eq true
      end
    end
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
    let(:staff)      { create :user }
    let(:admin)      { create :admin }
    let(:client)     { create :client_user }
    let(:volunteer)  { create :volunteer_user }
    let(:contractor) { create :contractor_user }

    let(:good_tennant)    { build :connection, relationship: 'tennant', user: client }
    let(:bad_tennant)     { build :connection, relationship: 'tennant', user: staff }
    let(:good_staff)      { build :connection, relationship: 'staff contact', user: staff }
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
