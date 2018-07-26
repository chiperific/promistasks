# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Property, type: :model do
  before :each do
    @property = FactoryBot.create(:property, certificate_number: 'string', serial_number: 'string', is_private: false)
    WebMock.reset_executed_requests!
  end

  describe 'must be valid against the schema' do
    let(:no_name_or_address)            { build :property, name: nil, address: nil }
    let(:no_city)                       { build :property, city: nil }
    let(:no_state)                      { build :property, state: nil }
    let(:no_postal)                     { build :property, postal_code: nil }
    let(:no_creator)                    { build :property, creator_id: nil }
    let(:non_unique_name)               { build :property, name: @property.name }
    let(:non_unique_address)            { build :property, address: @property.address }
    let(:non_unique_certificate_number) { build :property, certificate_number: @property.certificate_number }
    let(:non_unique_serial_number)      { build :property, serial_number: @property.serial_number }

    context 'against the schema' do
      it 'in order to save' do
        expect { @property.save!(validate: false) }.not_to raise_error
        expect { no_name_or_address.save!(validate: false) }.to             raise_error ActiveRecord::NotNullViolation
        expect { no_creator.save!(validate: false) }.to                     raise_error ActiveRecord::NotNullViolation
        expect { non_unique_name.save!(validate: false) }.to                raise_error ActiveRecord::RecordNotUnique
        expect { non_unique_address.save!(validate: false) }.to             raise_error ActiveRecord::RecordNotUnique
        expect { non_unique_certificate_number.save!(validate: false) }.to  raise_error ActiveRecord::RecordNotUnique
        expect { non_unique_serial_number.save!(validate: false) }.to       raise_error ActiveRecord::RecordNotUnique
      end
    end

    context 'against the model' do
      it 'in order to save' do
        expect(@property.save!).to eq true
        expect { no_name_or_address.save! }.to            raise_error ActiveRecord::RecordInvalid
        expect { no_creator.save! }.to                    raise_error ActiveRecord::RecordInvalid
        expect { non_unique_name.save! }.to               raise_error ActiveRecord::RecordInvalid
        expect { non_unique_address.save! }.to            raise_error ActiveRecord::RecordInvalid
        expect { non_unique_certificate_number.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { non_unique_serial_number.save! }.to      raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe 'requires booleans to be in a state:' do
    let(:bad_private) { build :property, is_private: nil }
    let(:bad_default) { build :property, is_default: nil }
    let(:bad_ignore)  { build :property, ignore_budget_warning: nil }
    let(:bad_created) { build :property, created_from_api: nil }

    it 'is_private' do
      expect { bad_private.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_private.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'is_default' do
      expect { bad_default.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_default.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'ignore_budget_warning' do
      expect { bad_ignore.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_ignore.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'created_from_api' do
      expect { bad_created.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_created.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'limits records by scope' do
    let(:no_title)          { create :property }
    let(:public_property)   { create :property, is_private: false }
    let(:private_property)  { create :property, is_private: true }
    let(:archived_property) { create :property, discarded_at: Time.now }
    let(:user)              { create :oauth_user }
    let(:this_user)         { create :property, creator: user }
    let(:this_user_also)    { create :property, creator: user }
    let(:not_this_user)     { create :property }
    let(:task_creator)      { create :task, creator: user, property: not_this_user }
    let(:task_owner)        { create :task, owner: user, property: not_this_user }

    it '#needs_title returns only records without a certificate_number' do
      expect(Property.needs_title).not_to include @property
      expect(Property.needs_title).not_to include archived_property
      expect(Property.needs_title).to include no_title
    end

    it '#public_visible returns only records where is_private is false' do
      expect(Property.public_visible).not_to include private_property
      expect(Property.public_visible).to include public_property
    end

    it '#created_by returns only records where the user is the creator' do
      expect(Property.created_by(user)).not_to include @property
      expect(Property.created_by(user)).not_to include not_this_user
      expect(Property.created_by(user)).not_to include archived_property
      expect(Property.created_by(user)).to include this_user
      expect(Property.created_by(user)).to include this_user_also
    end

    it '#with_tasks_for returns only records with a related task where the user is a creator or owner' do
      @property
      this_user_also
      this_user
      archived_property
      not_this_user
      user
      task_creator
      task_owner
      Task.all.each(&:reload)
      Property.all.each(&:reload)
      user.reload

      expect(Property.with_tasks_for(user)).not_to include @property
      expect(Property.with_tasks_for(user)).not_to include this_user_also
      expect(Property.with_tasks_for(user)).not_to include this_user
      expect(Property.with_tasks_for(user)).not_to include archived_property
      expect(Property.with_tasks_for(user)).to include not_this_user
    end

    it '#related_to returns a combo of #created_by and #with_tasks_for' do
      @property
      this_user_also
      this_user
      archived_property
      not_this_user
      user
      task_creator
      task_owner
      expect(Property.related_to(user)).not_to include @property
      expect(Property.related_to(user)).not_to include archived_property
      expect(Property.related_to(user)).to include this_user_also
      expect(Property.related_to(user)).to include this_user
      expect(Property.related_to(user)).to include not_this_user
    end

    it '#visible_to returns a combo of #created_by, #with_tasks_for, and #public_visible' do
      @property.update(is_private: false)
      this_user_also
      this_user
      archived_property
      not_this_user
      user
      task_creator
      task_owner
      expect(Property.visible_to(user)).not_to include archived_property
      expect(Property.visible_to(user)).to include @property
      expect(Property.visible_to(user)).to include this_user_also
      expect(Property.visible_to(user)).to include this_user
      expect(Property.visible_to(user)).to include not_this_user
    end

    it '#over_budget' do
      @property
      this_user_also
      this_user
      archived_property
      not_this_user
      user
      task_creator
      task_owner
      over_budget = FactoryBot.create(:property, budget: 10)
      FactoryBot.create(:task, property: over_budget, cost: 12)

      expect(Property.over_budget).to include over_budget
      expect(Property.over_budget).not_to include @property
    end

    it '#nearing_budget' do
      @property
      this_user_also
      this_user
      archived_property
      not_this_user
      user
      task_creator
      task_owner
      nearing_budget = FactoryBot.create(:property, budget: 20)
      FactoryBot.create(:task, property: nearing_budget, cost: 12)

      expect(Property.nearing_budget).to include nearing_budget
      expect(Property.nearing_budget).not_to include @property
    end

    it '#archived is alias of #discarded' do
      expect(Property.archived).to eq Property.discarded
    end

    it '#active is alias of #kept' do
      expect(Property.active).to eq Property.kept
    end
  end

  describe 'adds lat/long' do
    context 'when address is good' do
      pending 'after validation'
      pending 'when address has changed'
    end
    context 'except when is_default' do
      pending 'doesn\'t get added'
    end
  end

  describe '#good_address?' do
    pending 'returns false if city, state or postal code are missing'
    pending 'returns true if all address fields are present'
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

  describe '#needs_title?' do
    context 'when certificate_number is blank' do
      pending 'returns false'
    end

    context 'when certificate_number is nil' do
      pending 'returns false'
    end

    context 'when certificate_number is not nil or blank' do
      pending 'returns true'
    end
  end

  describe '#google_map' do
    context 'when address is bad' do
      pending 'returns a string'
    end

    context 'when address is good' do
      pending 'returns a URL'
    end
  end

  describe '#google_street_view' do
    pending 'returns a URL'
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

  describe '#ensure_tasklist_exists_for(user)' do
    let(:user) { create :oauth_user }

    it 'doesn\'t make an API call if the tasklist exists with a google_id' do
      @property.save
      WebMock.reset_executed_requests!
      @property.update(name: 'New name!')
      expect(WebMock).not_to have_requested(:post, Constant::Regex::TASKLIST)
    end

    it 'creates a tasklist' do
      prev_count = Tasklist.count

      @property.ensure_tasklist_exists_for(user)
      expect(Tasklist.count).to eq prev_count + 1
    end

    it 'makes an API call' do
      new_property = FactoryBot.build(:property, is_private: true)
      WebMock.reset_executed_requests!
      new_property.ensure_tasklist_exists_for(new_property.creator)
      expect(WebMock).to have_requested(:post, Constant::Regex::TASKLIST).once
    end
  end

  describe '#can_be_viewed_by(user)' do
    let(:user)               { create :user }
    let(:creator_prop)       { create :property, creator: user, is_private: true }
    let(:tasks_creator_prop) { create :property, is_private: true }
    let(:tasks_owner_prop)   { create :property, is_private: true }
    let(:public_prop)        { create :property, is_private: false }
    let(:failing_prop)       { create :property, is_private: true }

    it 'returns true if user is the creator' do
      expect(creator_prop.can_be_viewed_by(user)).to eq true
    end

    it 'returns true if the property has tasks related to the user' do
      FactoryBot.create(:task, creator: user, property: tasks_creator_prop)
      FactoryBot.create(:task, owner: user, property: tasks_owner_prop)
      tasks_creator_prop.reload
      tasks_owner_prop.reload

      expect(tasks_creator_prop.can_be_viewed_by(user)).to eq true
      expect(tasks_owner_prop.can_be_viewed_by(user)).to eq true
    end

    it 'returns true if the property is public' do
      expect(public_prop.can_be_viewed_by(user)).to eq true
    end

    it 'returns false if none are true' do
      expect(failing_prop.can_be_viewed_by(user)).to eq false
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

  describe 'is_default validations' do
    let(:default_prop)  { build :property, is_default: true}
    let(:normal_prop)   { build :property }
    let(:discarded_prop) { build :property, discarded_at: Time.now }

    describe '#only_one_default' do
      it 'only fires if record is marked as default' do
        expect(normal_prop).not_to receive(:only_one_default)
        normal_prop.save!

        expect(default_prop).to receive(:only_one_default)
        default_prop.save!
      end

      it 'returns true if there\'s no default' do
        expect(default_prop.send(:only_one_default)).to eq true
      end

      it 'returns true if this record is the only default' do
        default_prop.save
        expect(default_prop.send(:only_one_default)).to eq true
      end

      it 'sets is_default to false' do
        default_prop.save
        normal_prop.is_default = true
        normal_prop.save
        expect(normal_prop.is_default).to eq false
      end
    end

    describe '#default_must_be_private' do
      it 'won\'t fire if discarded_at is not nil' do
        expect(discarded_prop).not_to receive(:default_must_be_private)
        discarded_prop.save
      end

      it 'won\'t fire if is_default is false' do
        expect(normal_prop).not_to receive(:default_must_be_private)
        normal_prop.save
      end

      it 'won\'t fire if is_private is true' do
        default_prop.is_private = true
        expect(default_prop).not_to receive(:default_must_be_private)
        default_prop.save
      end

      it 'only fires if all conditions are met' do
        expect(default_prop).to receive(:default_must_be_private)
        default_prop.update(is_private: false)
      end

      it 'sets is_private to true' do
        default_prop.is_private = false
        default_prop.save
        expect(default_prop.is_private).to eq true
      end
    end

    describe '#refuse_to_discard_default' do
      it 'won\'t fire if discarded_at is nil' do
        expect(default_prop).not_to receive(:refuse_to_discard_default)
        default_prop.save
      end

      it 'won\'t fire if is_default is false' do
        expect(discarded_prop).not_to receive(:refuse_to_discard_default)
        discarded_prop.save
      end

      it 'only fires if conditions are met' do
        default_prop.discarded_at = Time.now
        expect(default_prop).to receive(:refuse_to_discard_default)
        default_prop.save
      end

      it 'sets discarded_at to nil' do
        discarded_prop.save
        expect(discarded_prop.discarded_at).not_to eq nil

        discarded_prop.send(:refuse_to_discard_default)
        expect(discarded_prop.discarded_at).to eq nil
      end
    end
  end

  describe '#create_tasklists' do
    before :each do
      @user  = FactoryBot.create(:oauth_user)
      @user2 = FactoryBot.create(:oauth_user)
      @user3 = FactoryBot.create(:oauth_user)
      @private_property = FactoryBot.build(:property, creator: @user, is_private: true)
      @public_property  = FactoryBot.build(:property, creator: @user, is_private: false)
      @discarded_private_property = FactoryBot.build(:property, creator: @user, is_private: true, discarded_at: Time.now - 1.hour)
      WebMock.reset_executed_requests!
    end

    it 'only fires if discarded_at is blank' do
      expect(@discarded_private_property).not_to receive(:create_tasklists)
      @discarded_private_property.save!

      expect(@private_property).to receive(:create_tasklists)
      @private_property.save!
    end

    context 'when private' do
      it 'creates a new Tasklist for the Creator' do
        expect(@private_property).to receive(:ensure_tasklist_exists_for).with(@private_property.creator)
        @private_property.save!
      end
    end

    context 'when public' do
      it 'creates a new Tasklist for all User.staff' do
        user_count = User.count
        expect(@public_property).to receive(:ensure_tasklist_exists_for).exactly(user_count).times
        @public_property.save!
      end
    end
  end

  describe '#cascade_by_privacy' do
    let(:user)  { create :oauth_user }
    let(:user2) { create :oauth_user }
    let(:user3) { create :oauth_user }
    let(:private_property) { create :property, name: 'Private Property', creator: user, is_private: true }
    let(:public_property)  { create :property, name: 'Public Property', creator: user, is_private: false }
    let(:task) { create :task, property: public_property, creator: user, owner: user2 }

    context 'when privacy hasn\'t changed' do
      it 'doesn\'t trigger' do
        expect(private_property).not_to receive(:cascade_by_privacy)
        private_property.save!
      end
    end

    context 'when privacy has changed' do
      it 'does trigger' do
        expect(private_property).to receive(:cascade_by_privacy)
        private_property.update(is_private: false)
      end
    end

    context 'when true to false (was private, now public)' do
      it 'adds the tasklist to other users' do
        private_property.save
        WebMock.reset_executed_requests!
        count = User.staff_except(private_property.creator).count
        private_property.update(is_private: false)
        expect(WebMock).to have_requested(:post, Constant::Regex::TASKLIST).times(count)
      end
    end

    context 'when false to true (was public, now private)' do
      it 'removes the tasklist from other users' do
        user
        user2
        user3
        public_property.save!
        task
        count = User.without_tasks_for(public_property).count
        public_property.update(is_private: true)
        expect(WebMock).to have_requested(:delete, Constant::Regex::TASKLIST).times(count)
      end
    end
  end

  describe '#discard_tasks_and_delete_tasklists' do
    let(:discarded_property) { create :property, name: 'about to be discarded' }
    let(:task1) { create :task, property: discarded_property }
    let(:task2) { create :task, property: discarded_property }
    let(:task3) { create :task, property: discarded_property }

    it 'only fires after a property is discarded' do
      expect(@property).not_to receive(:discard_tasks_and_delete_tasklists)
      @property.save!

      discarded_property.discarded_at = Time.now
      expect(discarded_property).to receive(:discard_tasks_and_delete_tasklists)
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

  describe '#update_tasklists' do
    before :each do
      @user  = FactoryBot.create(:oauth_user)
      @user2 = FactoryBot.create(:oauth_user)
      @user3 = FactoryBot.create(:oauth_user)
      @private_property = FactoryBot.create(:property, creator: @user, is_private: true)
      @public_property  = FactoryBot.create(:property, creator: @user, is_private: false)
      WebMock.reset_executed_requests!
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
end
