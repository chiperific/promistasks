# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Property, type: :model do
  before :each do
    stub_request(:any, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).to_return(body: 'You did it!', status: 200)
    @property                      = FactoryBot.create(:property, certificate_number: 'string', google_id: 'string', serial_number: 'string')
    @no_name_or_address            = FactoryBot.build(:property, name: nil, address: nil)
    @non_unique_address            = FactoryBot.build(:property, address: @property.address)
    @non_unique_certificate_number = FactoryBot.build(:property, certificate_number: @property.certificate_number)
    @non_unique_google_id          = FactoryBot.build(:property, google_id: @property.google_id)
    @non_unique_serial_number      = FactoryBot.build(:property, serial_number: @property.serial_number)
    WebMock::RequestRegistry.instance.reset!
  end

  describe 'must be valid against the schema' do
    it 'in order to save' do
      expect { @property.save!(validate: false) }.not_to raise_error
      expect { @no_name_or_address.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { @non_unique_address.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { @non_unique_certificate_number.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { @non_unique_google_id.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { @non_unique_serial_number.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
    end
  end

  describe 'must be valid against the model' do
    it 'in order to save' do
      expect(@property.save!).to eq true
      expect { @no_name_or_address.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @non_unique_address.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @non_unique_certificate_number.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @non_unique_google_id.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @non_unique_serial_number.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'limits records by scope' do
    let(:no_title) { create :property }
    it '#needs_title returns only records without a certificate_number' do
      expect(Property.needs_title).not_to include @property
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
    let(:task1) { create :task, cost: Money.new(300_00), property: @property }
    let(:task2) { create :task, cost: Money.new(450_00), property: @property }
    let(:task3) { create :task, cost: Money.new(105_00), property: @property }

    it 'returns the budget minus the cost of associated tasks' do
      task1
      task2
      task3

      expect(@property.budget_remaining).to eq Money.new(6_645_00)
    end
  end

  describe '#tasklist_users' do
    let(:user1) { create :user }
    let(:user2) { create :user }

    it 'returns all users where a matching record isn\'t present in the join table' do
      user1
      user2

      expect(@property.tasklist_users).to include user1
      expect(@property.tasklist_users).to include user2

      FactoryBot.create(:exclude_property_user, user: user1, property: @property)

      expect(@property.tasklist_users).not_to include user1
      expect(@property.tasklist_users).to include user2
    end
  end

  describe '#assign_from_api_fields!' do
    it 'uses a json hash to assign record values' do
      property = Property.new
      tasklist_json = JSON.parse(file_fixture('tasklist_json_spec.json').read)

      expect(property.name).to eq nil
      expect(property.selflink).to eq nil

      property.assign_from_api_fields!(tasklist_json)

      expect(property.name).not_to eq nil
      expect(property.selflink).not_to eq nil
    end
  end

  describe '#not_discarded?' do
    let(:discarded) { build :property, discarded_at: Time.now - 1.hour }

    it 'returns true if discarded_at is blank' do
      expect(@property.send(:not_discarded?)).to eq true
    end

    it 'returns false if discarded_at is set' do
      expect(discarded.send(:not_discarded?)).to eq false
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
    before :each do
      stub_request(:any, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).to_return(body: 'You did it!', status: 200)
      @user  = FactoryBot.create(:oauth_user)
      @user2 = FactoryBot.create(:oauth_user)
      @user3 = FactoryBot.create(:oauth_user)
      @private_property = FactoryBot.build(:property, creator: @user, private: true)
      @public_property  = FactoryBot.build(:property, creator: @user, private: false)
      @discarded_private_property = FactoryBot.build(:property, creator: @user, private: true, discarded_at: Time.now - 1.hour)
      WebMock::RequestRegistry.instance.reset!
    end

    it 'only fires if discarded_at is blank' do
      @discarded_private_property.save!
      expect(WebMock).not_to have_requested(:any, 'https://www.googleapis.com/tasks/v1/users/@me/lists')

      @private_property.save!
      expect(WebMock).to have_requested(:post, 'https://www.googleapis.com/tasks/v1/users/@me/lists')
    end

    context 'when private' do
      it 'creates a new Tasklist for the Creator' do
        @private_property.save!
        expect(WebMock).to have_requested(:post, 'https://www.googleapis.com/tasks/v1/users/@me/lists').once
      end
    end
    context 'when public' do
      it 'creates a new Tasklist for all User.staff' do
        @public_property.save!
        user_count = User.count
        expect(WebMock).to have_requested(:post, 'https://www.googleapis.com/tasks/v1/users/@me/lists').times(user_count)
      end
    end
  end

  describe '#update_with_api' do
    before :each do
      stub_request(:any, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).to_return(body: 'You did it!', status: 200)
      @user  = FactoryBot.create(:oauth_user)
      @user2 = FactoryBot.create(:oauth_user)
      @user3 = FactoryBot.create(:oauth_user)
      @private_property = FactoryBot.create(:property, creator: @user, private: true)
      @public_property  = FactoryBot.create(:property, creator: @user, private: false)
      @discarded_private_property = FactoryBot.create(:property, creator: @user, private: true, discarded_at: Time.now - 1.hour)
      @discarded_public_property  = FactoryBot.create(:property, creator: @user, private: false, discarded_at: Time.now - 1.hour)
      WebMock::RequestRegistry.instance.reset!
    end

    it 'should only fire if name is changed or the record is discarded' do
      @private_property.update(creator: @user2)
      expect(WebMock).not_to have_requested(:patch, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/)

      @private_property.update(name: 'Now it\'s called something else!')
      expect(WebMock).to have_requested(:patch, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).once

      @private_property.update(discarded_at: Time.now - 10.minutes)
      expect(WebMock).to have_requested(:patch, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).once
    end

    context 'when private' do
      context 'and discarded' do
        it 'deletes the Tasklist for the Creator' do
          @discarded_private_property.update(name: 'discarded private property')
          expect(WebMock).to have_requested(:delete, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).once
        end
      end

      context 'and not discarded' do
        it 'updates a Tasklist for the Creator' do
          @private_property.update(name: 'not discarded private property')
          expect(WebMock).to have_requested(:patch, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).once
        end
      end
    end

    context 'when public' do
      context 'and discarded' do
        it 'deletes the Tasklist for all users' do
          user_count = User.count
          @discarded_public_property.update(name: 'discarded public property')
          expect(WebMock).to have_requested(:delete, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).times(user_count)
        end
      end

      context 'and not discarded' do
        it 'updates a Tasklist for all users' do
          user_count = User.count
          @public_property.update(name: 'not discarded public property')
          expect(WebMock).to have_requested(:patch, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).times(user_count)
        end
      end
    end
  end

  describe '#propagate_to_api_by_privacy' do
    before :each do
      stub_request(:any, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).to_return(body: 'You did it!', status: 200)
      @user  = FactoryBot.create(:oauth_user)
      @user2 = FactoryBot.create(:oauth_user)
      @user3 = FactoryBot.create(:oauth_user)
      @private_property = FactoryBot.create(:property, name: 'Private Property', creator: @user, private: true)
      @public_property  = FactoryBot.create(:property, name: 'Public Property', creator: @user, private: false)
      WebMock::RequestRegistry.instance.reset!
    end

    context 'when privacy hasn\'t changed' do
      it 'doesn\'t trigger' do
        expect(@private_property).not_to receive(:propagate_to_api_by_privacy)
        @private_property.save!
      end
    end

    context 'when privacy has changed' do
      it 'does trigger' do
        expect(@private_property).to receive(:propagate_to_api_by_privacy)
        @private_property.update(private: false)
      end
    end

    context 'when true to false (was private, now public)' do
      it 'removes the tasklist from other users' do
        @private_property.save!
        user_count = User.count - 1
        @private_property.update(private: false)
        expect(WebMock).to have_requested(:post, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).times(user_count)
      end
    end

    context 'when false to true (was public, now private)' do
      it 'adds the tasklist to other users' do
        @public_property.save!
        user_count = User.count - 1
        @public_property.update(private: true)
        expect(WebMock).to have_requested(:delete, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).times(user_count)
      end
    end
  end
end
