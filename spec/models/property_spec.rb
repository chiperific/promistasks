# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Property, type: :model do
  let(:property) { create :property, certificate_number: 'string', google_id: 'string', serial_number: 'string' }

  let(:no_name_or_address) { build :property, name: nil, address: nil }
  let(:non_unique_address) { build :property, address: property.address }
  let(:non_unique_certificate_number) { build :property, certificate_number: property.certificate_number }
  let(:non_unique_google_id) { build :property, google_id: property.google_id }
  let(:non_unique_serial_number) { build :property, serial_number: property.serial_number }

  describe 'must be valid against the schema' do
    it 'in order to save' do
      expect { property.save!(validate: false) }.not_to raise_error
      expect { no_name_or_address.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { non_unique_address.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { non_unique_certificate_number.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { non_unique_google_id.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { non_unique_serial_number.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
    end
  end

  describe 'must be valid against the model' do
    it 'in order to save' do
      expect(property.save!).to eq true
      expect { no_name_or_address.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { non_unique_address.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { non_unique_certificate_number.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { non_unique_google_id.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { non_unique_serial_number.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'limits records by scope' do
    let(:no_title) { create :property }
    it '#needs_title returns only records without a certificate_number' do
      expect(Property.needs_title).not_to include property
      expect(Property.needs_title).to include no_title
    end
  end

  describe '#full_address' do
    let(:big_addr) { create :property, address: 'addr1', city: 'city', postal_code: '12345' }
    let(:mid_addr) { create :property, address: 'addr2', postal_code: '12345' }
    let(:lil_addr) { create :property, address: 'addr3' }

    it 'concatentates the address' do
      expect(big_addr.full_address).to eq 'addr1, city, MI, 12345'
      expect(mid_addr.full_address).to eq 'addr2, 12345'
      expect(lil_addr.full_address).to eq 'addr3'
    end
  end

  describe '#budget_remaining' do
    let(:task1) { create :task, cost: Money.new(300_00), property: property }
    let(:task2) { create :task, cost: Money.new(450_00), property: property }
    let(:task3) { create :task, cost: Money.new(105_00), property: property }

    it 'returns the budget minus the cost of associated tasks' do
      task1
      task2
      task3

      expect(property.budget_remaining).to eq Money.new(6_645_00)
    end
  end

  describe '#tasklist_users' do
    let(:user1) { create :user }
    let(:user2) { create :user }

    it 'returns all users where a matching record isn\'t present in the join table' do
      property
      user1
      user2

      expect(property.tasklist_users).to include user1
      expect(property.tasklist_users).to include user2

      FactoryBot.create(:exclude_property_user, user: user1, property: property)

      expect(property.tasklist_users).not_to include user1
      expect(property.tasklist_users).to include user2
    end
  end

  describe '#assign_from_api_fields' do
    it 'uses a json hash to assign record values' do
      property = Property.new
      tasklist_json = JSON.parse(file_fixture('tasklist_json_spec.json').read)

      expect(property.name).to eq nil
      expect(property.selflink).to eq nil

      property.assign_from_api_fields(tasklist_json)

      expect(property.name).not_to eq nil
      expect(property.selflink).not_to eq nil
    end
  end

  describe '#name_and_address' do
    let(:no_name) { build :property, name: nil }
    let(:no_address) { build :property, address: nil }

    it 'copies the fields to eachother if one was blank' do
      no_name.save
      no_name.reload
      expect(no_name.name).to eq no_name.address

      no_address.save
      no_address.reload
      expect(no_address.address).to eq no_address.name
    end
  end

  describe '#default_budget' do
    let(:no_budget) { build :property }
    let(:custom_budget) { build :property, budget: 500 }

    it 'sets a budget if one isn\'t present' do
      expect(no_budget.budget).to eq nil

      no_budget.save
      no_budget.reload

      expect(no_budget.budget).to eq Money.new(7_500_00)
    end

    it 'won\'t change a budget that\'s already set' do
      custom_budget.save
      custom_budget.reload

      expect(custom_budget.budget).to eq Money.new(500_00)
    end
  end

  describe '#create_with_api' do
    pending 'creates a new Tasklist for all User.staff'
  end

  describe '#update_with_api' do
    pending 'should only fire if name is changed'
    pending 'updates the Property as a Tasklist for all User.staff'
  end
end
