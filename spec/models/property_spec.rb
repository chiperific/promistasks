# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Property, type: :model do
  before :each do
    User.destroy_all
    Property.destroy_all
    Tasklist.destroy_all
    TaskUser.destroy_all
    stub_request(:any, Constant::Regex::TASKLIST).to_return(
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:tasklist_json).marshal_dump.to_json }
    )
    stub_request(:any, Constant::Regex::TASK).to_return(
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json },
      { headers: {"Content-Type"=> "application/json"}, status: 200, body: FactoryBot.create(:task_json).marshal_dump.to_json }
    )
    @property                      = FactoryBot.create(:property, certificate_number: 'string', serial_number: 'string')
    @no_name_or_address            = FactoryBot.build(:property, name: nil, address: nil)
    @no_creator                    = FactoryBot.build(:property, creator_id: nil)
    @non_unique_address            = FactoryBot.build(:property, address: @property.address)
    @non_unique_certificate_number = FactoryBot.build(:property, certificate_number: @property.certificate_number)
    @non_unique_serial_number      = FactoryBot.build(:property, serial_number: @property.serial_number)

    WebMock::RequestRegistry.instance.reset!
  end

  describe 'must be valid against the schema' do
    it 'in order to save' do
      expect { @property.save!(validate: false) }.not_to raise_error
      expect { @no_name_or_address.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { @no_creator.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { @non_unique_address.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { @non_unique_certificate_number.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { @non_unique_serial_number.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
    end
  end

  describe 'must be valid against the model' do
    it 'in order to save' do
      expect(@property.save!).to eq true
      expect { @no_name_or_address.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @no_creator.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @non_unique_address.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @non_unique_certificate_number.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @non_unique_serial_number.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'limits records by scope' do
    let(:no_title) { create :property }
    let(:public_property) { create :property, is_private: false }
    let(:archived_property) { create :property, discarded_at: Time.now }

    it '#needs_title returns only records without a certificate_number' do
      expect(Property.needs_title).not_to include @property
      expect(Property.needs_title).to include no_title
    end

    it '#public_visible returns only records where is_private is false' do
      expect(Property.public_visible).not_to include @property
      expect(Property.public_visible).to include public_property
    end

    it '#archived is alias of #discarded' do
      expect(Property.archived).to eq Property.discarded
    end

    it '#active is alias of #kept' do
      expect(Property.active).to eq Property.kept
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

  describe '#create_tasklist_for(user)' do
    let(:user) { create :oauth_user }

    it 'returns "already exists" if the tasklist exists with a google_id' do
      expect(@property.create_tasklist_for(@property.creator)).to eq 'already exists'
    end

    it 'creates a tasklist' do
      prev_count = Tasklist.count

      @property.create_tasklist_for(user)
      expect(Tasklist.count).to eq prev_count + 1
    end

    it 'makes an API call' do
      new_property = FactoryBot.build(:property)
      WebMock::RequestRegistry.instance.reset!
      new_property.save!
      expect(WebMock).to have_requested(:post, Constant::Regex::TASKLIST).once
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
      @user  = FactoryBot.create(:oauth_user)
      @user2 = FactoryBot.create(:oauth_user)
      @user3 = FactoryBot.create(:oauth_user)
      @private_property = FactoryBot.build(:property, creator: @user, is_private: true)
      @public_property  = FactoryBot.build(:property, creator: @user, is_private: false)
      @discarded_private_property = FactoryBot.build(:property, creator: @user, is_private: true, discarded_at: Time.now - 1.hour)
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
      @user  = FactoryBot.create(:oauth_user)
      @user2 = FactoryBot.create(:oauth_user)
      @user3 = FactoryBot.create(:oauth_user)
      @private_property = FactoryBot.create(:property, creator: @user, is_private: true)
      @public_property  = FactoryBot.create(:property, creator: @user, is_private: false)
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
    let(:user)  { create :oauth_user }
    let(:user2) { create :oauth_user }
    let(:user3) { create :oauth_user }
    let(:private_property) { create :property, name: 'Private Property', creator: user, is_private: true }
    let(:public_property)  { create :property, name: 'Public Property', creator: user, is_private: false }

    context 'when privacy hasn\'t changed' do
      it 'doesn\'t trigger' do
        expect(private_property).not_to receive(:propagate_to_api_by_privacy)
        private_property.save!
      end
    end

    context 'when privacy has changed' do
      it 'does trigger' do
        expect(private_property).to receive(:propagate_to_api_by_privacy)
        private_property.update(is_private: false)
      end
    end

    context 'when true to false (was private, now public)' do
      it 'adds the tasklist to other users' do
        private_property.save!
        WebMock::RequestRegistry.instance.reset!
        count = User.count - 1
        private_property.update(is_private: false)
        expect(WebMock).to have_requested(:post, Constant::Regex::TASKLIST).times(count)
      end
    end

    context 'when false to true (was public, now private)' do
      it 'removes the tasklist from other users' do
        public_property.save!
        count = public_property.tasklists.count - 1
        public_property.update(is_private: true)
        expect(WebMock).to have_requested(:delete, Constant::Regex::TASKLIST).times(count)
      end
    end
  end

  describe '#discard_tasks!' do
    let(:discarded_property) { create :property, name: 'about to be discarded' }
    let(:task1) { create :task, property: discarded_property }
    let(:task2) { create :task, property: discarded_property }
    let(:task3) { create :task, property: discarded_property }

    it 'only fires after a property is discarded' do
      expect(@property).not_to receive(:discard_tasks!)
      @property.save!

      discarded_property.discarded_at = Time.now
      expect(discarded_property).to receive(:discard_tasks!)
      discarded_property.save!
    end

    it 'marks all associated tasks as discarded' do
      expect(task1.discarded_at).to eq nil
      expect(task2.discarded_at).to eq nil
      expect(task3.discarded_at).to eq nil

      discarded_property.update(discarded_at: Time.now)

      task1.reload
      task2.reload
      task3.reload

      expect(task1.discarded_at).not_to eq nil
      expect(task2.discarded_at).not_to eq nil
      expect(task3.discarded_at).not_to eq nil
    end
  end
end
