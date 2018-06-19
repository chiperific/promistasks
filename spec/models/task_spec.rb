# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Task, type: :model do
  before :each do
    @creator        = FactoryBot.create(:oauth_user)
    @owner          = FactoryBot.create(:oauth_user)
    @property       = FactoryBot.create(:property)
    @task           = FactoryBot.build(:task, property: @property, creator: @creator, owner: @owner)
    @completed_task = FactoryBot.build(:task, property: @property, creator: @creator, owner: @owner, completed_at: Time.now - 1.hour)
    @updated_task   = FactoryBot.create(:task, property: @property, creator: @creator, owner: @owner)
    WebMock.reset_executed_requests!
  end

  describe 'must be valid' do
    let(:no_title)       { build :task, property: @property, creator: @creator, owner: @owner, title: nil }
    let(:no_creator)     { build :task, property: @property, owner: @owner, creator_id: nil }
    let(:no_owner)       { build :task, property: @property, creator: @creator, owner_id: nil }
    let(:no_property)    { build :task, property_id: nil, creator: @creator, owner: @owner }
    let(:bad_visibility) { build :task, property: @property, creator: @creator, owner: @owner, visibility: 4 }
    let(:bad_priority)   { build :task, property: @property, creator: @creator, owner: @owner, priority: 'wrong thing' }

    context 'against the schema' do
      it 'in order to save' do
        expect(@task.save!(validate: false)).to eq true
        expect { no_title.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_creator.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_owner.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_property.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      end
    end

    context 'against the model' do
      it 'in order to save' do
        expect(@task.save!).to eq true
        expect { no_title.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_creator.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_owner.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_property.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { bad_visibility.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { bad_priority.save! }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe 'requires uniqueness' do
    it 'on title and property' do
      @task.save
      duplicate = FactoryBot.build(:task, title: @task.title, property: @task.property)

      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires booleans be in a state:' do
    let(:bad_license)       { build :task, property: @property, creator: @creator, owner: @owner, license_required: nil }
    let(:bad_needs_no_info) { build :task, property: @property, creator: @creator, owner: @owner, needs_more_info: nil, due: Time.now + 3.hours, budget: Money.new(300_00), priority: 'low' }
    let(:bad_needs_info)    { build :task, property: @property, creator: @creator, owner: @owner, needs_more_info: nil }
    let(:bad_created)       { build :task, property: @property, creator: @creator, owner: @owner, created_from_api: nil }

    it 'license_required' do
      expect { bad_license.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_license.save! }.to raise_error ActiveRecord::RecordInvalid
    end

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
  end

  describe 'limits records by scope' do
    let(:has_good_info1) { create :task, property: @property, creator: @creator, owner: @owner, due: Time.now + 3.days, priority: 'medium', budget: 500 }
    let(:has_good_info2) { create :task, property: @property, creator: @creator, owner: @owner, due: Time.now + 2.days, priority: 'high', budget: 800 }
    let(:visibility_1)   { create :task, property: @property, creator: @creator, owner: @owner, visibility: 1 }
    let(:visibility_2)   { create :task, property: @property, creator: @creator, owner: @owner, visibility: 2 }
    let(:user) { create :user }
    let(:related_one) { create :task, creator: user }
    let(:related_two) { create :task, creator: user }

    it '#needs_more_info returns only tasks where needs_more_info is false' do
      @task.save

      expect(Task.needs_more_info).to include @task
      expect(Task.needs_more_info).not_to include @completed_task
      expect(Task.needs_more_info).not_to include has_good_info1
      expect(Task.needs_more_info).not_to include has_good_info2
    end

    it '#in_process returns only tasks where completed is nil' do
      @task.save
      @completed_task.save

      expect(Task.in_process).to include @task
      expect(Task.in_process).to include has_good_info1
      expect(Task.in_process).not_to include @completed_task
    end

    it '#complete returns only tasks where completed is not nil' do
      @completed_task.save
      @task.save

      expect(Task.complete).to include @completed_task
      expect(Task.complete).not_to include @task
      expect(Task.complete).not_to include has_good_info1
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

  describe '#assign_from_api_fields' do
    it 'returns false if task_json is null' do
      task = Task.new
      expect(task.assign_from_api_fields(nil)).to eq false
    end

    it 'uses a json hash to assign record values' do
      task = Task.new
      task_json = JSON.parse(file_fixture('task_json_spec.json').read)

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

  describe '#update_task_users' do
    before :each do
      @no_api_change  = FactoryBot.create(:task, property: @property, creator: @creator, owner: @owner)
      @new_user       = FactoryBot.create(:oauth_user, name: 'New user')
      @new_property   = FactoryBot.create(:property, name: 'New property', is_private: false, creator: @new_user)
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
        t.license_required = true
        t.owner_type = 'Admin Staff'
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

  describe '#delete_task_users' do
    let(:discarded_task) { create :task, discarded_at: Time.now }

    it 'won\'t fire if discarded_at was not just set' do
      expect(discarded_task).not_to receive(:delete_task_users)
      discarded_task.update(title: 'Im discarded')

      @task.save
      expect(@task).not_to receive(:delete_task_users)
      @task.update(title: 'Im not discarded')
    end

    it 'only fires if discarded_at was just set' do
      @task.save
      expect(@task).to receive(:delete_task_users)
      @task.discard
    end

    it 'destroys all related task_user records' do
      @task.save
      @task.reload
      count = TaskUser.count
      @task.discard
      expect(TaskUser.count).to eq count - 2
    end
  end

  describe '#saved_changes_to_users?' do
    before :each do
      @task.save
      @task.reload
      @new_user = FactoryBot.create(:oauth_user)
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
        t.license_required = true
        t.needs_more_info = true
        t.owner_type = 'Admin Staff'
      end
      no_api_change.save!

      expect(no_api_change.send(:saved_changes_to_api_fields?)).to eq false
    end

    it 'returns true if any API fields have changed' do
      title_change.update(title: 'New title')
      notes_change.update(notes: 'New notes content')
      due_change.update(due: Time.now + 2.weeks)
      completed_at_change.update(completed_at: Time.now - 3.minutes)

      expect(title_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(notes_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(due_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(completed_at_change.send(:saved_changes_to_api_fields?)).to eq true
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

  describe '#due_cant_be_past' do
    let(:past_due)   { build :task, property: @property, creator: @creator, owner: @owner, due: Time.now - 1.hour }
    let(:future_due) { build :task, property: @property, creator: @creator, owner: @owner, due: Time.now + 1.hour }

    it 'returns true if due is nil' do
      @task.save
      expect(@task.errors[:due].empty?).to eq true
    end

    it 'adds an error if due is in the past' do
      past_due.save
      expect(past_due.errors[:due]).to eq ['must be in the future']
    end

    it 'returns true if due is in the future' do
      future_due.save
      expect(future_due.errors[:due].empty?).to eq true
    end
  end

  describe '#decide_record_completeness' do
    let(:five_strikes)  { build :task, property: @property, creator: @creator, owner: @owner }
    let(:four_strikes)  { build :task, property: @property, creator: @creator, owner: @owner, budget: 50_00 }
    let(:three_strikes) { build :task, property: @property, creator: @creator, owner: @owner, priority: 'medium', budget: 50_00 }
    let(:two_strikes)   { build :task, property: @property, creator: @creator, owner: @owner, due: Time.now + 1.hour }
    let(:one_strike)    { build :task, property: @property, creator: @creator, owner: @owner, due: Time.now + 1.hour, priority: 'medium' }
    let(:zero_strikes)  { build :task, property: @property, creator: @creator, owner: @owner, due: Time.now + 1.hour, priority: 'medium', budget: 50_00 }

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
end
