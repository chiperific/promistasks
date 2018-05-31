# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Property, type: :model do
  before :each do
    @tasklist_json = FactoryBot.create(:tasklist_json).marshal_dump.to_json
    stub_request(:any, Constant::Regex::TASKLIST).to_return(headers: {"Content-Type"=> "application/json"}, body: @tasklist_json, status: 200)
    stub_request(:any, Constant::Regex::TASK).to_return(headers: {"Content-Type"=> "application/json"}, body: @tasklist_json, status: 200)
    @property                      = FactoryBot.create(:property, certificate_number: 'string', serial_number: 'string')
    @no_name_or_address            = FactoryBot.build(:property, name: nil, address: nil)
    @non_unique_address            = FactoryBot.build(:property, address: @property.address)
    @non_unique_certificate_number = FactoryBot.build(:property, certificate_number: @property.certificate_number)
    @non_unique_serial_number      = FactoryBot.build(:property, serial_number: @property.serial_number)
    WebMock::RequestRegistry.instance.reset!
  end

  describe 'must be valid against the schema' do
    it 'in order to save' do
      expect { @property.save!(validate: false) }.not_to raise_error
      expect { @no_name_or_address.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { @non_unique_address.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { @non_unique_certificate_number.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { @non_unique_serial_number.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
    end
  end

  describe 'must be valid against the model' do
    it 'in order to save' do
      expect(@property.save!).to eq true
      expect { @no_name_or_address.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @non_unique_address.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @non_unique_certificate_number.save! }.to raise_error ActiveRecord::RecordInvalid
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

  describe '#default_budget' do
    pending 'fires before an event is saved'
    pending 'sets a budget if one isn\'t set'
    pending 'doesn\'t change the budget if one is already set'
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

  describe '#unsynced_name_address?' do
    let(:both) { build :property }
    let(:neither) { build :property, name: nil, address: nil }
    let(:unsynced_name) { build :property, address: nil }
    let(:unsynced_address) { build :property, name: nil }

    it 'returns false if both are present' do
      expect(both.send(:unsynced_name_address?)).to eq false
    end

    it 'returns false if neither are present' do
      expect(neither.send(:unsynced_name_address?)).to eq false
    end

    it 'returns true if they are out of sync' do
      expect(unsynced_name.send(:unsynced_name_address?)).to eq true
      expect(unsynced_address.send(:unsynced_name_address?)).to eq true
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

  describe '#create_with_api' do
    before :each do
      User.destroy_all
      Property.destroy_all
      Tasklist.destroy_all
      stub_request(:any, Constant::Regex::TASKLIST).to_return(
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json }
      )
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
      User.destroy_all
      Property.destroy_all
      Tasklist.destroy_all
      stub_request(:any, Constant::Regex::TASKLIST).to_return(
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json }
      )
      @user  = FactoryBot.create(:oauth_user)
      @user2 = FactoryBot.create(:oauth_user)
      @user3 = FactoryBot.create(:oauth_user)
      @private_property = FactoryBot.create(:property, creator: @user, private: true)
      @public_property  = FactoryBot.create(:property, creator: @user, private: false)
      # @discarded_private_property = FactoryBot.create(:property, creator: @user, private: true, discarded_at: Time.now - 1.hour)
      # @discarded_public_property  = FactoryBot.create(:property, creator: @user, private: false, discarded_at: Time.now - 1.hour)
      WebMock::RequestRegistry.instance.reset!
    end

    it 'should only fire if name is changed' do
      @private_property.update(creator: @user2)
      expect(WebMock).not_to have_requested(:any, Constant::Regex::TASKLIST)

      @private_property.update(name: 'Now it\'s called something else!')
      expect(WebMock).to have_requested(:post, Constant::Regex::TASKLIST).once
    end

    context 'when private' do
      it 'updates a Tasklist for the Creator' do
        @private_property.update(name: 'not discarded private property')
        expect(WebMock).to have_requested(:patch, Constant::Regex::TASKLIST).once
      end
    end

    context 'when public' do
      it 'updates a Tasklist for all users' do
        user_count = User.count
        @public_property.update(name: 'not discarded public property')
        expect(WebMock).to have_requested(:patch, Constant::Regex::TASKLIST).times(user_count)
      end
    end
  end

  describe '#propagate_to_api_by_privacy' do
    before :each do
      User.destroy_all
      Property.destroy_all
      Tasklist.destroy_all
      stub_request(:any, Constant::Regex::TASKLIST).to_return(
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
        { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json }
      )
      # stub_request(:any, Constant::Regex::TASK).to_return(headers: {"Content-Type"=> "application/json"}, body: @task_json, status: 200)
      @user = FactoryBot.create(:oauth_user)
      @user2 = FactoryBot.create(:oauth_user)
      @user3 = FactoryBot.create(:oauth_user)
      @private_property = FactoryBot.create(:property, name: 'Private Property', creator: @user, private: true)
      @public_property  = FactoryBot.create(:property, name: 'Public Property', creator: @user, private: false)
      WebMock::RequestRegistry.instance.reset!
    end

    after :each do
      User.destroy_all
      Property.destroy_all
      Tasklist.destroy_all
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
      it 'adds the tasklist to other users' do
        @private_property.save!
        count = User.count - 1
        @private_property.update(private: false)
        expect(WebMock).to have_requested(:post, Constant::Regex::TASKLIST).times(count)
      end
    end

    context 'when false to true (was public, now private)' do
      it 'removes the tasklist from other users' do
        @public_property.save!
        count = @public_property.tasklists.count - 1
        @public_property.update(private: true)
        expect(WebMock).to have_requested(:delete, Constant::Regex::TASKLIST).times(count)
      end
    end
  end

  describe '#discard_tasks!' do
    before :each do
      @tasklist_json = FactoryBot.create(:tasklist_json).marshal_dump.to_json
      stub_request(:any, Constant::Regex::TASKLIST).to_return(headers: {"Content-Type"=> "application/json"}, body: @tasklist_json, status: 200)
      stub_request(:any, Constant::Regex::TASK).to_return(headers: {"Content-Type"=> "application/json"}, body: @tasklist_json, status: 200)
      @discarded_property = FactoryBot.create(:property, name: 'about to be discarded')
      @task1 = FactoryBot.create(:task, property: @discarded_property)
      @task2 = FactoryBot.create(:task, property: @discarded_property)
      @task3 = FactoryBot.create(:task, property: @discarded_property)
    end

    it 'only fires after a property is discarded' do
      expect(@property).not_to receive(:discard_tasks!)
      @property.save!

      @discarded_property.discarded_at = Time.now
      expect(@discarded_property).to receive(:discard_tasks!)
      @discarded_property.save!
    end

    it 'marks all associated tasks as discarded' do
      expect(@task1.discarded_at).to eq nil
      expect(@task2.discarded_at).to eq nil
      expect(@task3.discarded_at).to eq nil

      @discarded_property.update(discarded_at: Time.now)

      @task1.reload
      @task2.reload
      @task3.reload

      expect(@task1.discarded_at).not_to eq nil
      expect(@task2.discarded_at).not_to eq nil
      expect(@task3.discarded_at).not_to eq nil
    end
  end
end
