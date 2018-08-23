# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'must be valid' do
    let(:organization) { build :organization }
    let(:no_name) { build :organization, name: nil }
    let(:no_domain) { build :organization, domain: nil }

    context 'against the schema' do
      it 'in order to save' do
        expect { organization.save!(validate: false) }.not_to raise_error
        expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_domain.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      end
    end

    context 'against the model' do
      it 'in order to save' do
        expect { organization.save! }.not_to raise_error
        expect { no_name.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_domain.save! }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#highlander' do
    let(:organization) { create :organization }

    context 'when no other organization exists' do
      it 'does nothing' do
        expect(organization).to receive(:highlander)

        organization.save

        expect(organization.errors.any?).to eq false
      end
    end

    context 'when an organization already exists' do
      before :each do
        organization
        @second = build(:organization, name: 'Not family promise', domain: 'as far as the eye can see')
      end

      it 'adds an error to #name' do
        expect(@second.valid?).to eq false
        expect(@second.errors[:name].present?).to eq true
      end

      it 'prevents the record from being created' do
        expect { @second.save }.not_to change { Organization.count }
      end
    end
  end
end
