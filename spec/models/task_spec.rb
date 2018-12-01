# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Task, type: :model do
  before :each do
    @creator        = create(:oauth_user)
    @owner          = create(:oauth_user)
    @property       = create(:property)
    @default        = create(:property, is_default: true)
    @task           = build(:task, property: @property, creator: @creator, owner: @owner)
    @completed_task = build(:task, property: @property, creator: @creator, owner: @owner, completed_at: Time.now - 1.hour)
    @updated_task   = create(:task, property: @property, creator: @creator, owner: @owner)
    WebMock.reset_executed_requests!
  end

  describe 'must be valid' do
    let(:no_title)       { build :task, property: @property, creator: @creator, owner: @owner, title: nil }
    let(:no_creator)     { build :task, property: @property, owner: @owner, creator_id: nil }
    let(:no_owner)       { build :task, property: @property, creator: @creator, owner_id: nil }
    let(:no_property)    { build :task, property_id: nil, creator: @creator, owner: @owner }
    let(:no_visibility)  { build :task, property: @property, creator: @creator, owner: @owner, visibility: nil }
    let(:bad_visibility) { build :task, property: @property, creator: @creator, owner: @owner, visibility: 4 }
    let(:bad_priority)   { build :task, property: @property, creator: @creator, owner: @owner, priority: 64 }
    let(:no_min_vols)    { build :task, property: @property, creator: @creator, owner: @owner, min_volunteers: nil }
    let(:no_max_vols)    { build :task, property: @property, creator: @creator, owner: @owner, max_volunteers: nil }

    context 'against the schema' do
      it 'in order to save' do
        expect(@task.save!(validate: false)).to eq true
        expect { no_title.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_creator.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_owner.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_property.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_visibility.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_min_vols.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_max_vols.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      end
    end

    context 'against the model' do
      it 'in order to save' do
        expect(@task.save!).to eq true
        expect { no_title.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_creator.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_owner.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_property.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_visibility.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { bad_visibility.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { bad_priority.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_min_vols.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_max_vols.save! }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe 'requires uniqueness' do
    it 'on title and property' do
      @task.save
      duplicate = build(:task, title: @task.title, property: @task.property)

      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires booleans be in a state:' do
    let(:bad_needs_no_info) { build :task, property: @property, creator: @creator, owner: @owner, needs_more_info: nil, due: Date.tomorrow, budget: Money.new(300_00), priority: 'low' }
    let(:bad_needs_info)    { build :task, property: @property, creator: @creator, owner: @owner, needs_more_info: nil }
    let(:bad_created)       { build :task, property: @property, creator: @creator, owner: @owner, created_from_api: nil }
    let(:bad_vol_group)     { build :task, property: @property, creator: @creator, owner: @owner, volunteer_group: nil }
    let(:bad_professional)  { build :task, property: @property, creator: @creator, owner: @owner, professional: nil }

    it 'needs_more_info can\'t be stateless because of the model' do
      # `before_save :decide_completeness` potects the state
      expect { bad_needs_no_info.save!(validate: false) }.not_to raise_error
      expect { bad_needs_no_info.save! }.not_to raise_error
      expect { bad_needs_info.save!(validate: false) }.not_to raise_error
      expect { bad_needs_info.save! }.not_to raise_error
    end

    it 'created_from_api' do
      expect { bad_created.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_created.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'volunteer_group' do
      expect { bad_vol_group.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_vol_group.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'professional' do
      expect { bad_professional.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_professional.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'limits records by scope:' do
    let(:has_good_info1) { create :task, property: @property, creator: @creator, owner: @owner, due: Date.tomorrow, priority: 'medium', budget: 500 }
    let(:has_good_info2) { create :task, property: @property, creator: @creator, owner: @owner, due: Date.tomorrow, priority: 'high', budget: 800 }
    let(:has_cost)       { create :task, property: @property, creator: @creator, owner: @owner, cost: 25 }
    let(:visibility_1)   { create :task, property: @property, creator: @creator, owner: @owner, visibility: 1 }
    let(:visibility_2)   { create :task, property: @property, creator: @creator, owner: @owner, visibility: 2 }
    let(:user) { create :user }
    let(:related_one) { create :task, creator: user }
    let(:related_two) { create :task, creator: user }
    let(:old)         { create :task, property: @property, creator: @creator, owner: @owner, created_at: Time.now - 8.days }
    let(:due_later)   { create :task, property: @property, creator: @creator, owner: @owner, due: Date.today + 10.days }
    let(:past_due)    { create :task, property: @property, creator: @creator, owner: @owner }
    let(:on_primary)  { create :task, property: @default, creator: @creator, owner: @owner }

    it '#complete returns only tasks where completed is not nil' do
      @completed_task.save
      @task.save

      expect(Task.complete).to include @completed_task
      expect(Task.complete).not_to include @task
      expect(Task.complete).not_to include has_good_info1
    end

    it '#created_since(time) returns only tasks where created_at is greater than the given time' do
      @task.save
      @completed_task.save
      time = Time.now - 2.days

      expect(Task.created_since(time)).not_to include old
      expect(Task.created_since(time)).to include @task
      expect(Task.created_since(time)).to include @completed_task
    end

    it '#due_within(day_num)' do
      day_num = 7

      expect(Task.due_within(day_num)).not_to include due_later
      expect(Task.due_within(day_num)).not_to include visibility_1
      expect(Task.due_within(day_num)).to include has_good_info1
      expect(Task.due_within(day_num)).to include has_good_info2
    end

    it '#except_primary returns only tasks where the parent property\'s is_default is false' do
      @task.save
      @completed_task.save

      expect(Task.except_primary).to include @task
      expect(Task.except_primary).to include @completed_task
      expect(Task.except_primary).not_to include on_primary
    end

    it '#has_cost returns only tasks where cost is not nil' do
      @task.save
      @completed_task.save

      expect(Task.has_cost).to include has_cost
      expect(Task.has_cost).not_to include @task
      expect(Task.has_cost).not_to include @completed_task
    end

    it '#in_process returns only tasks where completed is nil' do
      @task.save
      @completed_task.save

      expect(Task.in_process).to include @task
      expect(Task.in_process).to include has_good_info1
      expect(Task.in_process).not_to include @completed_task
    end

    it '#needs_more_info returns only tasks where needs_more_info is false' do
      @task.save

      expect(Task.needs_more_info).to include @task
      expect(Task.needs_more_info).not_to include @completed_task
      expect(Task.needs_more_info).not_to include has_good_info1
      expect(Task.needs_more_info).not_to include has_good_info2
    end

    it '#past_due' do
      past_due.update_columns(due: Date.today - 2.days)

      expect(Task.past_due).to include past_due
      expect(Task.past_due).not_to include due_later
      expect(Task.past_due).not_to include visibility_1
      expect(Task.past_due).not_to include has_good_info1
      expect(Task.past_due).not_to include has_good_info2
    end

    it '#public_visible returns only undiscarded tasks where visibility is set to everyone' do
      @task.save

      expect(Task.public_visible).to include visibility_1
      expect(Task.public_visible).not_to include visibility_2
      expect(Task.public_visible).not_to include @task
    end

    it '#related_to shows records where the user is the creator, owner or subject' do
      expect(Task.related_to(user)).to include related_one
      expect(Task.related_to(user)).to include related_two
      expect(Task.related_to(user)).not_to include has_good_info1
      expect(Task.related_to(user)).not_to include @task
    end

    it '#visible_to shows a combo of #related_to and public_visible' do
      expect(Task.visible_to(user)).to include related_one
      expect(Task.visible_to(user)).to include related_two
      expect(Task.visible_to(user)).to include visibility_1
      expect(Task.visible_to(user)).not_to include visibility_2
      expect(Task.visible_to(user)).not_to include has_good_info1
    end
  end

  describe '#active?' do
    it 'returns true if completed_at is blank' do
      @task.save
      expect(@task.completed_at.blank?).to eq true
      expect(@task.active?).to eq true
    end

    it 'returns false if completed_at is present' do
      @task.completed_at = Time.now
      @task.save
      expect(@task.completed_at.blank?).to eq false
      expect(@task.active?).to eq false
    end
  end

  describe '#archived?' do
    it 'returns false if discarded_at is blank' do
      @task.save
      expect(@task.discarded_at.present?).to eq false
      expect(@task.archived?).to eq false
    end

    it 'returns true if discarded_at is present' do
      @task.discarded_at = Time.now
      @task.save
      expect(@task.discarded_at.present?).to eq true
      expect(@task.archived?).to eq true
    end
  end

  describe '#assign_from_api_fields(task_json)' do
    it 'returns false if task_json is null' do
      task = Task.new
      expect(task.assign_from_api_fields(nil)).to eq false
    end

    it 'uses a json hash to assign record values' do
      task = Task.new
      task_json = create(:task_json)

      expect(task.title).to eq nil
      expect(task.notes).to eq nil
      expect(task.due).to eq nil
      expect(task.completed_at).to eq nil

      task.assign_from_api_fields(task_json)

      expect(task.title).not_to eq nil
      expect(task.notes).not_to eq nil
      expect(task.due).not_to eq nil
      expect(task.completed_at).not_to eq nil
    end
  end

  describe '#budget_remaining' do
    let(:no_budget)   { create :task, property: @property, creator: @creator, owner: @owner, cost: 250 }
    let(:no_cost)     { create :task, property: @property, creator: @creator, owner: @owner, budget: 250 }
    let(:both_moneys) { create :task, property: @property, creator: @creator, owner: @owner, budget: 300, cost: 250 }

    it 'returns nil if budget && cost are both nil' do
      @task.save
      expect(@task.budget_remaining).to eq nil
    end

    it 'returns the budget minus the cost if either is set' do
      no_budget
      no_cost
      both_moneys

      expect(no_budget.budget_remaining).to eq Money.new(-250_00)
      expect(no_cost.budget_remaining).to eq Money.new(250_00)
      expect(both_moneys.budget_remaining).to eq Money.new(50_00)
    end
  end

  describe '#cascade_completed' do
    let(:completed_task) { create :task, completed_at: Time.now }

    it 'won\'t fire if completed_at wasn\'t just set' do
      expect(completed_task).not_to receive(:cascade_completed)
      completed_task.update(title: 'did not change completed at')

      expect(@task).not_to receive(:cascade_completed)
      @task.save
    end

    it 'only fires if completed_at was just set' do
      @task.save
      expect(@task).to receive(:cascade_completed)
      @task.update(completed_at: Time.now)
    end

    it 'sets completed_at on all related task_user records' do
      @task.save
      @task.reload

      task_user_comps = @task.task_users.map(&:completed_at)
      expect(task_user_comps.include?(nil)).to eq true

      @task.update(completed_at: Time.now)
      task_user_comps = @task.task_users.map(&:completed_at)
      expect(task_user_comps.include?(nil)).to eq false
    end
  end

  describe '#change_task_users' do
    let(:new_creator) { create :oauth_user }
    let(:new_owner) { create :oauth_user }

    it 'won\'t fires if creator or owner hasn\'t changed' do
      @task.save
      expect(@task).not_to receive(:change_task_users)
      @task.update(title: 'new title entry')
    end

    it 'only fires if creator or owner has changed' do
      @task.save
      expect(@task).to receive(:change_task_users)
      @task.update(creator: new_creator)

      expect(@task).to receive(:change_task_users)
      @task.update(owner: new_owner)
    end

    context 'when creator has changed' do
      it 'deletes the old task_user' do
        @task.save
        @task.reload
        task_user = @task.task_users.where(user: @task.creator).first
        @task.update(creator: new_creator)
        expect { task_user.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it 'creates a new task_user' do
        @task.save
        @task.update(creator: new_creator)
        @task.reload
        task_user = @task.task_users.where(user: @task.creator).first
        expect(task_user.reload.user_id).not_to eq @task.creator_id_before_last_save
      end
    end

    context 'when owner has changed' do
      it 'deletes the old task_user' do
        @task.save
        @task.reload
        task_user = @task.task_users.where(user: @task.owner).first
        @task.update(owner: new_owner)
        expect { task_user.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it 'creates a new task_user' do
        @task.save
        @task.update(owner: new_owner)
        @task.reload
        task_user = @task.task_users.where(user: @task.owner).first
        expect(task_user.reload.user_id).not_to eq @task.owner_id_before_last_save
      end
    end
  end

  describe '#complete?' do
    it 'returns false if completed_at is blank' do
      @task.save
      expect(@task.completed_at.present?).to eq false
      expect(@task.complete?).to eq false
    end

    it 'returns true if completed_at is true' do
      @task.completed_at = Time.now
      @task.save
      expect(@task.completed_at.present?).to eq true
      expect(@task.complete?).to eq true
    end
  end

  describe '#create_task_users' do
    it 'only fires on record creation' do
      expect(@task).to receive(:create_task_users)
      @task.save
      expect(@task).not_to receive(:create_task_users)
      @task.update(title: 'New title')
    end

    it 'creates task_user records for creator and owner' do
      count = TaskUser.count
      @task.save
      expect(TaskUser.count).to eq count + 2
    end
  end

  describe '#ensure_task_user_exists_for' do
    let(:volunteer) { create :volunteer_user }
    let(:contractor) { create :contractor_user }

    it 'returns false for non-oauth_users' do
      @task.save
      expect(@task.ensure_task_user_exists_for(volunteer)).to eq false
    end

    it 'doesn\'t make task_users if they already exists' do
      @task.save
      count = TaskUser.count
      @task.ensure_task_user_exists_for(@task.creator)
      @task.ensure_task_user_exists_for(@task.owner)
      expect(TaskUser.count).to eq count
    end

    it 'creates task_user records for the creator and owner' do
      count = TaskUser.count
      @task.save
      expect(TaskUser.count).to eq count + 2
    end
  end

  describe '#on_default?' do
    it 'returns false if parent property is not default' do
      expect(@task.property.is_default?).to eq false
      expect(@task.on_default?).to eq false
    end

    it 'returns true if parent property is default' do
      @task.property = @default
      @task.save
      expect(@task.property.is_default?).to eq true
      expect(@task.on_default?).to eq true
    end
  end

  describe '#past_due?' do
    it 'returns false if due is blank' do
      @task.save
      expect(@task.due.blank?).to eq true
      expect(@task.past_due?).to eq false
    end

    it 'returns false if complete_at is present' do
      @task.completed_at = Time.now
      @task.save
      expect(@task.completed_at.present?).to eq true
      expect(@task.past_due?).to eq false
    end

    it 'returns false if due is greater than today' do
      @task.due = Date.today + 2.days
      @task.save
      expect(@task.past_due?).to eq false
    end

    it 'returns true if due is less than today' do
      @task.due = Date.today - 2.days
      @task.save
      expect(@task.past_due?).to eq true
    end
  end

  describe '#priority_color' do
    it 'returns a string if priority is between 0 and 4' do
      @task.save
      (0..4).to_a.each do |n|
        @task.update(priority: n)
        expect(@task.priority_color.length).to be > 3
      end
    end

    it 'returns a blank string if property is any other value' do
      @task.priority = nil
      @task.save
      expect(@task.priority_color).to eq ''

      @task.update_column(:priority, 64)
      expect(@task.priority_color).to eq ''
    end
  end

  describe '#public?' do
    it 'returns true if visibility is equal to 1' do
      @task.visibility = 1
      @task.save
      expect(@task.visibility).to eq 1
      expect(@task.public?).to eq true
    end

    it 'returns false if visibility does not equal 1' do
      @task.save
      expect(@task.visibility).to eq 0
      expect(@task.public?).to eq false
    end
  end

  describe '#related_to?(user)' do
    before :each do
      @task.save
    end

    it 'returns true if user is creator' do
      expect(@task.related_to?(@creator)).to eq true
    end

    it 'returns true if user is owner' do
      expect(@task.related_to?(@owner)).to eq true
    end

    it 'returns false if user isn\'t creator or owner' do
      unrelated_user = create(:oauth_user)

      expect(@task.related_to?(unrelated_user)).to eq false
    end
  end

  describe '#relocate' do
    let(:property) { create :property, creator: @creator }

    it 'won\'t fire if property_id hasn\'t changed' do
      expect(@updated_task).not_to receive(:relocate)
      @updated_task.update(owner: @creator)
    end

    it 'only fires if property_id has changed' do
      expect(@updated_task).to receive(:relocate)
      @updated_task.update(property: property)
    end

    it 'updates task_user.tasklist_gid for creator and owner' do
      old_tasklist_gid = @updated_task.task_users.where(user: @creator).first.tasklist_gid
      @updated_task.update(property: property)
      new_taskist_gid = @updated_task.task_users.where(user: @creator).first.tasklist_gid
      expect(new_taskist_gid).not_to eq old_tasklist_gid
    end
  end

  describe '#saved_changes_to_api_fields?' do
    let(:no_api_change) { create :task, property: @property, creator: @creator, owner: @owner }
    let(:new_user)      { create :oauth_user }
    let(:new_property)  { create :property }

    let(:title_change) { create :task, property: @property, creator: @creator, owner: @owner }
    let(:notes_change) { create :task, property: @property, creator: @creator, owner: @owner }
    let(:due_change) { create :task, property: @property, creator: @creator, owner: @owner }
    let(:completed_at_change) { create :task, property: @property, creator: @creator, owner: @owner }

    it 'returns false if no fields have changed' do
      no_api_change.tap do |t|
        t.priority = 'urgent'
        t.creator = new_user
        t.owner = new_user
        t.subject = new_user
        t.property_id = new_property.id
        t.budget = 167
        t.cost = 123
        t.visibility = 1
        t.needs_more_info = true
      end
      no_api_change.save!

      expect(no_api_change.send(:saved_changes_to_api_fields?)).to eq false
    end

    it 'returns true if any API fields have changed' do
      title_change.update(title: 'New title')
      notes_change.update(notes: 'New notes content')
      due_change.update(due: Date.today + 2.weeks)
      completed_at_change.update(completed_at: Time.now - 3.minutes)

      expect(title_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(notes_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(due_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(completed_at_change.send(:saved_changes_to_api_fields?)).to eq true
    end
  end

  describe '#saved_changes_to_users?' do
    before :each do
      @task.save
      @task.reload
      @new_user = create(:oauth_user)
    end

    it 'returns false if neither user fields have changed' do
      @task.save
      expect(@task.saved_changes_to_users?).to eq false
    end

    it 'returns true if creator_id changed' do
      @task.update(creator: @new_user)
      expect(@task.saved_changes_to_users?).to eq true
    end

    it 'returns true if owner_id changed' do
      @task.update(owner: @new_user)
      expect(@task.saved_changes_to_users?).to eq true
    end
  end

  describe '#status' do
    it 'returns "active" if completed_at is nil' do
      @task.save
      expect(@task.status).to eq 'active'
    end

    it 'returns "complete" if completed_at is present' do
      @task.completed_at = Time.now
      @task.save
      expect(@task.status).to eq 'complete'
    end
  end

  describe '#update_task_users' do
    before :each do
      @no_api_change  = create(:task, property: @property, creator: @creator, owner: @owner)
      @new_user       = create(:oauth_user, name: 'New user')
      @new_property   = create(:property, name: 'New property', is_private: false, creator: @new_user)
      WebMock.reset_executed_requests!
    end

    it 'should only fire if an api field is changed' do
      @no_api_change.tap do |t|
        t.priority = 'low'
        t.creator = @new_user
        t.owner = @new_user
        t.subject = @new_user
        t.property = @new_property
        t.budget = 50_00
        t.cost = 48_00
        t.visibility = 1
      end

      expect(@no_api_change).not_to receive(:update_task_users)
      @no_api_change.save!
    end

    it 'returns false if the users have changed' do
      @task.save
      expect(@task).to receive(:update_task_users).and_return false
      @task.update(creator: @new_user, owner: @new_user, title: 'new title')
    end

    it 'fires task_user.api_update' do
      @updated_task.update(title: 'new title')
      expect(WebMock).to have_requested(:patch, Constant::Regex::TASK).twice
    end
  end

  describe '#visible_to?(user)' do
    before :each do
      @unrelated_user = create(:oauth_user)
      @admin          = create(:admin)
      @staff          = create(:user)
      @not_client     = create(:contractor_user)
      @client         = create(:client_user)
    end

    it 'returns true if visibility is 1' do
      @task.visibility = 1
      @task.save
      expect(@task.visible_to?(@unrelated_user)).to eq true
      expect(@task.visible_to?(@client)).to eq true
    end

    it 'returns true if user is admin' do
      @task.save
      expect(@task.visible_to?(@admin)).to eq true
      @task.update(visibility: 2)
      expect(@task.visible_to?(@admin)).to eq true
    end

    it 'returns true if visibility is 0 and user is staff' do
      @task.visibility = 0
      @task.save
      expect(@task.visible_to?(@staff)).to eq true
    end

    it 'returns true if visibility is 2 and user is related to task' do
      @task.visibility = 2
      @task.save
      expect(@task.visible_to?(@creator)).to eq true
    end

    it 'returns true if visibility is 3 and user is not a client' do
      @task.visibility = 3
      @task.save
      expect(@task.visible_to?(@not_client)).to eq true
    end

    it 'returns false if conditions are not met' do
      @task.save # 0, visible to staff
      expect(@task.visible_to?(@client)).to eq false

      @task.update(visibility: 2) # visible to associated people
      expect(@task.visible_to?(@unrelated_user)).to eq false

      @task.update(visibility: 3) # not clients
      expect(@task.visible_to?(@client)).to eq false
    end
  end

  # start private methods

  describe '#decide_record_completeness' do
    let(:five_strikes)  { build :task, property: @property, creator: @creator, owner: @owner }
    let(:four_strikes)  { build :task, property: @property, creator: @creator, owner: @owner, budget: 50_00 }
    let(:three_strikes) { build :task, property: @property, creator: @creator, owner: @owner, priority: 'medium', budget: 50_00, estimated_hours: 10 }
    let(:two_strikes)   { build :task, property: @property, creator: @creator, owner: @owner, due: Time.now + 1.hour, priority: 'medium', budget: 50_00, min_volunteers: 1, max_volunteers: 1 }
    let(:one_strike)    { build :task, property: @property, creator: @creator, owner: @owner, due: Time.now + 1.hour, estimated_hours: 10, budget: 50_00, min_volunteers: 1, max_volunteers: 1 }
    let(:zero_strikes)  { build :task, property: @property, creator: @creator, owner: @owner, due: Time.now + 1.hour, priority: 'medium', budget: 50_00, estimated_hours: 10, min_volunteers: 1, max_volunteers: 1 }

    it 'sets needs_more_info based on strikes' do
      expect(five_strikes.needs_more_info).to eq false
      expect(four_strikes.needs_more_info).to eq false
      expect(three_strikes.needs_more_info).to eq false
      expect(two_strikes.needs_more_info).to eq false
      expect(one_strike.needs_more_info).to eq false
      expect(zero_strikes.needs_more_info).to eq false

      five_strikes.save
      four_strikes.save
      three_strikes.save
      two_strikes.save
      one_strike.save
      zero_strikes.save

      expect(five_strikes.needs_more_info).to eq true
      expect(four_strikes.needs_more_info).to eq true
      expect(three_strikes.needs_more_info).to eq false
      expect(two_strikes.needs_more_info).to eq false
      expect(one_strike.needs_more_info).to eq false
      expect(zero_strikes.needs_more_info).to eq false
    end
  end

  describe '#due_must_be_after_created' do
    let(:past_due)   { build :task, property: @property, creator: @creator, owner: @owner, due: Date.today - 1.day }
    let(:future_due) { build :task, property: @property, creator: @creator, owner: @owner, due: Date.today + 1.day }
    let(:past_due_hack)   { build :task, property: @property, creator: @creator, owner: @owner, due: Date.today - 1.day, created_at: Time.now - 2.days }

    it 'returns true if due is nil' do
      @task.save
      expect(@task.errors[:due].empty?).to eq true
    end

    it 'adds an error if due is older than created_at' do
      past_due.save
      expect(past_due.errors[:due]).to eq ['must be in the future']
    end

    it 'returns true if due is newer than created_at' do
      future_due.save
      expect(future_due.errors[:due].empty?).to eq true

      past_due_hack.save
      expect(past_due_hack.errors[:due].empty?).to eq true
    end
  end

  describe '#require_cost' do
    let(:complete_w_budget) { build :task, property: @property, creator: @creator, owner: @owner, completed_at: Time.now, budget: 400 }
    let(:complete_w_both)   { build :task, property: @property, creator: @creator, owner: @owner, completed_at: Time.now, budget: 400, cost: 250 }

    it 'ignores tasks that aren\'t complete' do
      @task.save
      expect(@task.errors[:cost].empty?).to eq true
    end

    it 'ignores tasks where budget isn\'t present' do
      @completed_task.save
      expect(@completed_task.errors[:cost].empty?).to eq true
    end

    it 'adds an error if there\'s a budget but no cost' do
      complete_w_budget.save
      expect(complete_w_budget.errors[:cost].empty?).to eq false
    end

    it 'ignores tasks where budget and cost are present' do
      complete_w_both.save
      expect(complete_w_both.errors[:cost].empty?).to eq true
    end
  end

  describe '#visibility_must_be_2' do
    let(:default_property) { create :property, is_default: true }
    let(:default_task) { build :task, property: default_property }

    it 'only fires if parent property is default and visibility is not 2' do
      expect(default_task).to receive(:visibility_must_be_2)
      default_task.save

      expect(@task).not_to receive(:visibility_must_be_2)
      @task.save
    end

    it 'sets the visibility to 2' do
      expect(default_task.visibility).not_to eq 2

      default_task.save
      default_task.reload

      expect(default_task.visibility).to eq 2
    end
  end
end
