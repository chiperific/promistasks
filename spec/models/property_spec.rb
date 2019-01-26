# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Property, type: :model do
  before :each do
    @property = create(:property, certificate_number: 'string', serial_number: 'string', is_private: false)
    WebMock.reset_executed_requests!
  end

  describe 'must be valid' do
    let(:no_name_or_address)            { build :property, name: nil, address: nil }
    let(:no_creator)                    { build :property, creator_id: nil }
    let(:non_unique_name)               { build :property, name: @property.name }
    let(:non_unique_address)            { build :property, address: @property.address }
    let(:non_unique_certificate_number) { build :property, certificate_number: @property.certificate_number }
    let(:non_unique_serial_number)      { build :property, serial_number: @property.serial_number }

    context 'against the schema' do
      it 'in order to save' do
        expect { @property.save!(validate: false) }.not_to raise_error
        expect { no_name_or_address.save!(validate: false) }.to       raise_error ActiveRecord::NotNullViolation
        expect { no_creator.save!(validate: false) }.to               raise_error ActiveRecord::NotNullViolation
        expect { non_unique_name.save!(validate: false) }.to          raise_error ActiveRecord::RecordNotUnique
        expect { non_unique_address.save!(validate: false) }.to       raise_error ActiveRecord::RecordNotUnique
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
    before :each do
      @no_title          = create(:property)
      @public_property   = create(:property, is_private: false)
      @private_property  = create(:property, is_private: true)
      @archived_property = create(:property, discarded_at: Time.now)
      @user              = create(:oauth_user)
      @this_user         = create(:property, creator: @user)
      @this_user_also    = create(:property, creator: @user)
      @not_this_user     = create(:property)
      @task_creator      = create(:task, creator: @user, property: @not_this_user)
      @task_owner        = create(:task, owner: @user, property: @not_this_user)
      @past              = create(:property, created_at: Time.now - 2.days)
      @present           = create(:property, created_at: Time.now)
      @future            = create(:property, created_at: Time.now + 2.days)
    end

    it '#needs_title returns only records without a certificate_number' do
      expect(Property.needs_title).not_to include @property
      expect(Property.needs_title).not_to include @archived_property
      expect(Property.needs_title).to include @no_title
    end

    it '#public_visible returns only records where is_private is false' do
      expect(Property.public_visible).not_to include @private_property
      expect(Property.public_visible).to include @public_property
    end

    it '#created_by returns only records where the user is the creator' do
      expect(Property.created_by(@user)).not_to include @property
      expect(Property.created_by(@user)).not_to include @not_this_user
      expect(Property.created_by(@user)).not_to include @archived_property
      expect(Property.created_by(@user)).to include @this_user
      expect(Property.created_by(@user)).to include @this_user_also
    end

    it '#with_tasks_for returns only records with a related task where the user is a creator or owner' do
      expect(Property.with_tasks_for(@user)).not_to include @property
      expect(Property.with_tasks_for(@user)).not_to include @this_user_also
      expect(Property.with_tasks_for(@user)).not_to include @this_user
      expect(Property.with_tasks_for(@user)).not_to include @archived_property
      expect(Property.with_tasks_for(@user)).to include @not_this_user
    end

    it '#related_to returns a combo of #created_by and #with_tasks_for' do
      expect(Property.related_to(@user)).not_to include @property
      expect(Property.related_to(@user)).not_to include @archived_property
      expect(Property.related_to(@user)).to include @this_user_also
      expect(Property.related_to(@user)).to include @this_user
      expect(Property.related_to(@user)).to include @not_this_user
    end

    it '#visible_to returns a combo of #created_by, #with_tasks_for, and #public_visible' do
      @property.update(is_private: false)
      expect(Property.visible_to(@user)).not_to include @archived_property
      expect(Property.visible_to(@user)).to include @property
      expect(Property.visible_to(@user)).to include @this_user_also
      expect(Property.visible_to(@user)).to include @this_user
      expect(Property.visible_to(@user)).to include @not_this_user
    end

    it '#over_budget' do
      over_budget = create(:property, budget: 10)
      create(:task, property: over_budget, cost: 12)

      expect(Property.over_budget).to include over_budget
      expect(Property.over_budget).not_to include @property
    end

    it '#nearing_budget' do
      nearing_budget = create(:property, budget: 20)
      create(:task, property: nearing_budget, cost: 12)

      expect(Property.nearing_budget).to include nearing_budget
      expect(Property.nearing_budget).not_to include @property
    end

    it '#created_since returns only Properties created since the provided time variable' do
      time = Time.now - 1.hour
      expect(Property.created_since(time)).to include @present
      expect(Property.created_since(time)).to include @future
      expect(Property.created_since(time)).not_to include @past
    end

    it '#archived is alias of #discarded' do
      expect(Property.archived).to eq Property.discarded
    end

    it '#active is alias of #kept' do
      expect(Property.active).to eq Property.kept
    end
  end

  describe 'limits record by class method scopes:' do
    before :each do
      @approved = create(:property_ready)
      @complete = create(:property_ready)
      @occupied = create(:property_ready)
      @pending =  create(:property_ready)
      @vacant =   create(:property_ready)

      create(:connection_stage, stage: 'approved', property: @approved)
      create(:connection_stage, stage: 'transferred title', property: @complete)
      create(:connection_stage, stage: 'moved in', property: @occupied)
      create(:connection_stage, stage: 'applied', property: @pending)
      create(:connection_stage, stage: 'vacated', property: @vacant)
    end

    it 'self.approved returns active properties where occupancy_status == approved applicant' do
      expect(Property.approved).to include @approved
      expect(Property.approved).not_to include @complete
      expect(Property.approved).not_to include @occupied
      expect(Property.approved).not_to include @pending
      expect(Property.approved).not_to include @vacant
    end

    it 'self.complete returns properties where occupancy_status == approved applicant' do
      expect(Property.complete).not_to include @approved
      expect(Property.complete).to include @complete
      expect(Property.complete).not_to include @occupied
      expect(Property.complete).not_to include @pending
      expect(Property.complete).not_to include @vacant
    end

    it 'self.occupied returns active properties where occupancy_status == occupied' do
      expect(Property.occupied).not_to include @approved
      expect(Property.occupied).not_to include @complete
      expect(Property.occupied).to include @occupied
      expect(Property.occupied).not_to include @pending
      expect(Property.occupied).not_to include @vacant
    end

    it 'self.pending returns active properties where occupancy_status == pending application' do
      expect(Property.pending).not_to include @approved
      expect(Property.pending).not_to include @complete
      expect(Property.pending).not_to include @occupied
      expect(Property.pending).to include @pending
      expect(Property.pending).not_to include @vacant
    end

    it 'self.vacant returns active properties where occupancy_status == vacant' do
      expect(Property.vacant).not_to include @approved
      expect(Property.vacant).not_to include @complete
      expect(Property.vacant).not_to include @occupied
      expect(Property.vacant).not_to include @pending
      expect(Property.vacant).to include @vacant
    end
  end

  describe '#address_has_changed?' do
    it 'returns true if address changed' do
      @property.address = 'new val'
      expect(@property.address_has_changed?).to eq true
    end

    it 'returns true if city changed' do
      @property.city = 'new val'
      expect(@property.address_has_changed?).to eq true
    end

    it 'returns true if state changed' do
      @property.state = 'new val'
      expect(@property.address_has_changed?).to eq true
    end

    it 'returns true if postal_code changed' do
      @property.postal_code = 'new val'
      expect(@property.address_has_changed?).to eq true
    end

    it 'returns false if no address fields have changed' do
      @property.name = 'new val'
      expect(@property.address_has_changed?).to eq false
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
      new_property = build(:property, is_private: true)
      WebMock.reset_executed_requests!
      new_property.ensure_tasklist_exists_for(new_property.creator)
      expect(WebMock).to have_requested(:post, Constant::Regex::TASKLIST).once
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

  describe '#good_address?' do
    let(:property) { create :property, address: 'address', city: 'city', state: 'state' }

    context 'when address is blank' do
      it 'retuns false' do
        property.update(address: nil)
        expect(property.good_address?).to eq false
      end
    end

    context 'when city is blank' do
      it 'retuns false' do
        property.update(city: '')
        expect(property.good_address?).to eq false
      end
    end

    context 'when state is blank' do
      it 'retuns false' do
        property.update(state: ' ')
        expect(property.good_address?).to eq false
      end
    end

    context 'when address, city and state are present' do
      it 'returns true' do
        expect(property.good_address?).to eq true
      end
    end
  end

  describe '#google_map' do
    let(:property) { create :property, address: '1600 Pennsylvania Ave NW', city: 'Washington', state: 'DC', postal_code: '20500' }

    context 'when not good_address?' do
      it 'returns no_property.jpg' do
        property.update(city: nil)
        expect(property.google_map).to eq 'no_property.jpg'
      end
    end

    context 'when good_address?' do
      it 'returns a url string' do
        expect(property.google_map[0..31]).to eq 'https://maps.googleapis.com/maps'
      end
    end
  end

  describe '#google_map_link' do
    let(:property) { create :property, address: '1600 Pennsylvania Ave NW', city: 'Washington', state: 'DC', postal_code: '20500' }

    context 'when not good_address?' do
      it 'returns false' do
        property.update(city: nil)
        expect(property.google_map_link).to eq false
      end
    end

    context 'when good_address?' do
      it 'returns a url string' do
        expect(property.google_map_link[0..30]).to eq 'https://www.google.com/maps/?q='
      end
    end
  end

  describe '#needs_title?' do
    context 'when certificate_number is blank' do
      let(:property) { create :property, certificate_number: '' }

      it 'returns true' do
        expect(property.needs_title?).to eq true
      end
    end

    context 'when certificate_number is nil' do
      let(:property) { create :property, certificate_number: nil }

      it 'returns true' do
        expect(property.needs_title?).to eq true
      end
    end

    context 'when certificate_number is not nil or blank' do
      let(:property) { create :property, certificate_number: '1a45' }

      it 'returns false' do
        expect(property.needs_title?).to eq false
      end
    end
  end

  describe '#occupancies' do
    before :each do
      @prop = create(:property_ready)
      @newest_connection = create(:connection_stage, property: @prop)
      @old_connection =    create(:connection_stage, stage_date: Date.today - 5.weeks, property: @prop)
      @newer_connection =  create(:connection_stage, stage_date: Date.today - 1.week, property: @prop)
      @not_occupancy =     create(:connection, property: @prop)
    end

    it 'returns only connections where relationship == tennant' do
      expect(@prop.occupancies.count).to eq 3
      expect(@prop.connections.count).to eq 4
      expect(@prop.occupancies).not_to include @not_occupancy
      expect(@prop.occupancies).to include @old_connection
      expect(@prop.occupancies).to include @newer_connection
      expect(@prop.occupancies).to include @newest_connection
    end

    it 'orders results by stage_date' do
      expect(@prop.occupancies.first).to eq @old_connection
      expect(@prop.occupancies.last).to eq @newest_connection
    end
  end

  describe '#occupancy_status' do
    it 'returns "vacant" if there are no associated occupancies' do
      expect(@property.occupancies.count).to eq 0
      expect(@property.occupancy_status).to eq 'vacant'
    end

    it 'returns "approved applicant" if the latest occupancy is "approved"' do
      @approved = create(:property_ready)
      create(:connection_stage, stage: 'approved', property: @approved)

      expect(@approved.occupancy_status).to eq 'approved applicant'
    end

    it 'returns "complete" if the latest occupancy is "transferred title"' do
      @complete = create(:property_ready)
      create(:connection_stage, stage: 'transferred title', property: @complete)

      expect(@complete.occupancy_status).to eq 'complete'
    end

    it 'returns "pending application" if the latest occupancy is "applied"' do
      @pending = create(:property_ready)
      create(:connection_stage, stage: 'applied', property: @pending)

      expect(@pending.occupancy_status).to eq 'pending application'
    end

    it 'returns "vacant" if the latest occupancy is "vacated" or "returned property"' do
      @vacant = create(:property_ready)
      create(:connection_stage, stage: 'vacated', property: @vacant)

      @returned = create(:property_ready)
      create(:connection_stage, stage: 'returned property', property: @returned)

      expect(@vacant.occupancies.count).not_to eq 0
      expect(@vacant.occupancy_status).to eq 'vacant'

      expect(@returned.occupancies.count).not_to eq 0
      expect(@returned.occupancy_status).to eq 'vacant'
    end

    it 'returns "occupied" if the latest stage is "moved in", "initial walkthrough", or "final walkthrough"' do
      @occupied = create(:property_ready)
      create(:connection_stage, stage: 'moved in', property: @occupied)

      @initial = create(:property_ready)
      create(:connection_stage, stage: 'initial walkthrough', property: @initial)

      @final = create(:property_ready)
      create(:connection_stage, stage: 'final walkthrough', property: @final)

      expect(@occupied.occupancies.count).not_to eq 0
      expect(@initial.occupancies.count).not_to eq 0
      expect(@final.occupancies.count).not_to eq 0

      expect(@occupied.occupancy_status).to eq 'occupied'
      expect(@initial.occupancy_status).to eq 'occupied'
      expect(@final.occupancy_status).to eq 'occupied'
    end
  end

  describe '#occupancy_details' do
    before :each do
      @approved = create(:property_ready)
      @vacant =   create(:property_ready)

      create(:connection_stage, stage: 'approved', property: @approved)
      create(:connection_stage, stage: 'vacated', property: @vacant)
    end

    it 'returns "Vacant" if there are no occupancies' do
      expect(@property.occupancies.count).to eq 0
      expect(@property.occupancy_details).to eq 'Vacant'
    end

    it 'returns "Vacant" if the last occupancy is "vacated" or "returned property"' do
      expect(@vacant.occupancies.count).to eq 1
      expect(@vacant.occupancy_details).to eq 'Vacant'
    end

    it 'formats a message based on the details of the most recent connection' do
      @approved.connections.first.user.update(name: 'Client')
      expect(@approved.occupancy_details).to eq 'Client approved on ' + Date.today.strftime('%b %-d, %Y')
    end
  end

  describe '#over_budget?' do
    it 'returns false if budget_remaining is not negative' do
      expect(@property.budget_remaining.positive?).to eq true
      expect(@property.over_budget?).to eq false
    end

    it 'returns false if ignore_budget_warning is true' do
      create(:task, property: @property, cost: Money.new(7_700_00))
      expect(@property.budget_remaining.negative?).to eq true
      @property.update(ignore_budget_warning: true)
      expect(@property.over_budget?).to eq false
    end

    it 'returns true if budget_remaining is negative and ignore_budget_warning is false' do
      create(:task, property: @property, cost: Money.new(7_700_00))
      expect(@property.over_budget?).to eq true
    end
  end

  describe '#update_tasklists' do
    before :each do
      @user  = create(:oauth_user)
      @user2 = create(:oauth_user)
      @user3 = create(:oauth_user)
      @private_property = create(:property, creator: @user, is_private: true)
      @public_property  = create(:property, creator: @user, is_private: false)
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

  describe '#visible_to?(user)' do
    let(:user)               { create :user }
    let(:creator_prop)       { create :property, creator: user, is_private: true }
    let(:tasks_creator_prop) { create :property, is_private: true }
    let(:tasks_owner_prop)   { create :property, is_private: true }
    let(:public_prop)        { create :property, is_private: false }
    let(:failing_prop)       { create :property, is_private: true }

    it 'returns true if user is the creator' do
      expect(creator_prop.visible_to?(user)).to eq true
    end

    it 'returns true if the property has tasks related to the user' do
      create(:task, creator: user, property: tasks_creator_prop)
      create(:task, owner: user, property: tasks_owner_prop)
      tasks_creator_prop.reload
      tasks_owner_prop.reload

      expect(tasks_creator_prop.visible_to?(user)).to eq true
      expect(tasks_owner_prop.visible_to?(user)).to eq true
    end

    it 'returns true if the property is public' do
      expect(public_prop.visible_to?(user)).to eq true
    end

    it 'returns false if none are true' do
      expect(failing_prop.visible_to?(user)).to eq false
    end
  end

  # private methods

  describe '#address_required' do
    context 'when property is default' do
      let(:property) { build :property, is_default: true }

      it 'doesn\'t fire' do
        expect(property).not_to receive(:address_required)
        property.save!
      end
    end

    context 'when property is created_from_api' do
      let(:property) { build :property, created_from_api: true }

      it 'doesn\'t fire' do
        expect(property).not_to receive(:address_required)
        property.save!
      end
    end

    context 'when property is not default nor created_from_api' do
      let(:property) { build :property, address: nil }

      it 'returns true if address is present' do
        property.address = 'has an address'

        expect(property.send(:address_required)).to eq true
      end

      it 'adds an error to address if address is blank' do
        expect(property.valid?).to eq false

        expect(property.errors[:address].present?).to be true
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

  describe '#create_tasklists' do
    before :each do
      @user  = create(:oauth_user)
      @user2 = create(:oauth_user)
      @user3 = create(:oauth_user)
      @private_property = build(:property, creator: @user, is_private: true)
      @public_property  = build(:property, creator: @user, is_private: false)
      @discarded_private_property = build(:property, creator: @user, is_private: true, discarded_at: Time.now - 1.hour)
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

  describe '#default_must_be_private' do
    let(:discarded_prop)   { build :property, discarded_at: Time.now, is_default: true, is_private: false }
    let(:not_default_prop) { build :property, discarded_at: nil, is_default: false, is_private: false }
    let(:private_prop)     { build :property, discarded_at: nil, is_default: true, is_private: true }
    let(:default_prop)     { build :property, discarded_at: nil, is_default: true, is_private: false }

    it 'won\'t fire if discarded_at is not nil' do
      expect(discarded_prop).not_to receive(:default_must_be_private)
      discarded_prop.save
    end

    it 'won\'t fire if is_default is false' do
      expect(not_default_prop).not_to receive(:default_must_be_private)
      not_default_prop.save
    end

    it 'won\'t fire if is_private is true' do
      expect(private_prop).not_to receive(:default_must_be_private)
      private_prop.save
    end

    it 'only fires if all conditions are met' do
      expect(default_prop).to receive(:default_must_be_private)
      default_prop.save
    end

    it 'sets is_private to true' do
      expect(default_prop.is_private?).to eq false
      default_prop.send(:default_must_be_private)
      expect(default_prop.is_private?).to eq true
    end
  end

  describe '#discard_relations' do
    context 'when discarded_at is not present' do
      let(:active_prop) { build :property, discarded_at: nil }

      it 'doesn\'t fire' do
        expect(active_prop).not_to receive(:discard_relations)
        active_prop.save
      end
    end

    context 'when discarded_at is present' do
      before :each do
        @discarded_prop = create(:property)
      end

      it 'fires' do
        expect(@discarded_prop).to receive(:discard_relations)

        @discarded_prop.discard
      end

      it 'discards any associated connections' do
        3.times do
          create(:connection, property: @discarded_prop)
        end
        expect(@discarded_prop.connections.active.count).to eq 3

        @discarded_prop.discard

        expect(@discarded_prop.connections.active.count).to eq 0
      end

      it 'discards any associated payments (that are paid)' do
        3.times do
          create(:payment, property: @discarded_prop, paid: Date.today)
        end
        expect(@discarded_prop.payments.active.count).to eq 3

        @discarded_prop.discard

        expect(@discarded_prop.payments.active.count).to eq 0
      end
    end
  end

  describe '#discard_tasks_and_delete_tasklists' do
    let(:discarded_property) { create :property, name: 'about to be discarded' }
    let(:task1) { create :task, property: discarded_property, completed_at: Time.now }
    let(:task2) { create :task, property: discarded_property, completed_at: Time.now }
    let(:task3) { create :task, property: discarded_property, completed_at: Time.now }

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

  describe '#refuse_to_discard_hastily' do
    let(:hasty) { create :property, name: 'don\'t be so hasty little hobbit' }

    it 'fires on save' do
      expect(hasty).to receive(:refuse_to_discard_hastily)

      hasty.discard
    end

    context 'when self.tasks.in_process.size > 0' do
      before :each do
        2.times do
          create(:task, property: hasty)
        end
      end

      it 'adds an error to :archive' do
        hasty.discard
        expect(hasty.errors[:archive].first).to eq 'failed because 2 active tasks exist'
      end
    end

    context 'when self.payments.not_paid.size > 0' do
      before :each do
        2.times do
          create(:payment, property: hasty)
        end
      end

      it 'adds an error to :archive' do
        hasty.discard
        expect(hasty.errors[:archive].first).to eq 'failed because 2 active payments exist'
      end
    end

    context 'when self.tasks.in_process.size == 0 && self.payments.not_paid.size == 0' do
      before :each do
        2.times do
          create(:task, property: hasty, completed_at: Time.now)
          create(:payment, property: hasty, paid: Date.today)
        end
      end

      it 'does nothing' do
        hasty.discard

        expect(hasty.errors.any?).to eq false
      end
    end
  end

  describe '#refuse_to_discard_default' do
    let(:active_prop)      { build :property, discarded_at: nil, is_default: true }
    let(:not_default_prop) { build :property, discarded_at: nil, is_default: false }
    let(:discarded_prop)   { build :property, discarded_at: Time.now, is_default: true }

    it 'won\'t fire if discarded_at is nil' do
      expect(active_prop).not_to receive(:refuse_to_discard_default)
      active_prop.save
    end

    it 'won\'t fire if is_default is false' do
      expect(not_default_prop).not_to receive(:refuse_to_discard_default)
      not_default_prop.save
    end

    it 'only fires if conditions are met' do
      expect(discarded_prop).to receive(:refuse_to_discard_default)
      discarded_prop.save
    end

    it 'sets discarded_at to nil' do
      expect(discarded_prop.discarded_at).not_to eq nil

      discarded_prop.send(:refuse_to_discard_default)
      expect(discarded_prop.discarded_at).to eq nil
    end
  end

  describe '#undiscard_relations' do
    let(:never_discarded) { create :property, discarded_at: nil }
    let(:still_discarded) { create :property, discarded_at: Time.now }

    context 'when discarded_at was not present before the last save' do
      it 'doesn\'t fire' do
        expect(never_discarded).not_to receive(:undiscard_relations)
        never_discarded.update(name: 'never been discarded')
      end
    end

    context 'when discarded_at is not nil' do
      it 'doesn\'t fire' do
        expect(still_discarded).not_to receive(:undiscard_relations)
        still_discarded.update(name: 'still discarded')
      end
    end

    context 'when discarded_at is no longer nil' do
      before :each do
        @undiscarded = create(:property, discarded_at: Time.now - 10.minutes)
      end

      it 'undiscards any associated connections' do
        3.times do
          create(:connection, property: @undiscarded, discarded_at: Time.now - 9.minutes)
        end

        expect(@undiscarded.connections.count).to eq 3
        expect(@undiscarded.connections.active.count).to eq 0

        @undiscarded.undiscard
        @undiscarded.reload

        expect(@undiscarded.connections.active.count).to eq 3
      end

      it 'undiscards any associated payments' do
        3.times do
          create(:payment, property: @undiscarded, discarded_at: Time.now - 9.minutes)
        end

        expect(@undiscarded.payments.count).to eq 3
        expect(@undiscarded.payments.active.count).to eq 0

        @undiscarded.undiscard
        @undiscarded.reload

        expect(@undiscarded.payments.active.count).to eq 3
      end
    end
  end

  describe '#use_address_for_name' do
    let(:with_name) { build :property, name: 'I have a name' }
    let(:no_name) { build :property, name: nil }

    context 'when name is not blank' do
      it 'doesn\'t fire' do
        expect(with_name).not_to receive(:use_address_for_name)
        with_name.save
      end
    end

    context 'when name is blank' do
      it 'sets the name from the address' do
        expect(no_name.name).to eq nil

        no_name.send(:use_address_for_name)

        expect(no_name.name.present?).to eq true
      end
    end
  end
end
