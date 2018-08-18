# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ParkUser, type: :model do
  describe 'must be valid' do
    context 'against the schema' do
      it 'in order to save' do
      end
    end

    context 'against the model' do
      it 'in order to save' do
      end
    end
  end

  it 'validates relationship inclusion' do
  end

  describe '#relationship_must_match_user_type' do
    let(:staff)      { create :user }
    let(:admin)      { create :admin }
    let(:client)     { create :client_user }
    let(:volunteer)  { create :volunteer_user }
    let(:contractor) { create :contractor_user }

    let(:no_staff)        { build :park_user, user_id: nil }
    let(:good_tennant)    { build :park_user, relationship: 'tennant', user: client }
    let(:bad_tennant)     { build :park_user, relationship: 'tennant', user: staff }
    let(:good_staff)      { build :park_user, relationship: 'staff contact', user: staff }
    let(:bad_staff)       { build :park_user, relationship: 'staff contact', user: client }
    let(:good_contractor) { build :park_user, relationship: 'contractor', user: contractor }
    let(:bad_contractor)  { build :park_user, relationship: 'contractor', user: volunteer }
    let(:good_volunteer)  { build :park_user, relationship: 'volunteer', user: volunteer }
    let(:bad_volunteer)   { build :park_user, relationship: 'volunteer', user: client }

    it 'returns false if user_id is blank' do
      expect(no_staff.save).to eq false
      expect(no_staff.send(:relationship_must_match_user_type)).to eq false
    end

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
end
