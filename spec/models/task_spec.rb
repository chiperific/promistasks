# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Task, type: :model do
  before :each do
    stub_request(:any, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).to_return(body: 'You did it!', status: 200)
    @task           = FactoryBot.build(:task)
    @no_title       = FactoryBot.build(:task, title: nil)
    @no_creator     = FactoryBot.build(:task, creator_id: nil)
    @no_owner       = FactoryBot.build(:task, owner_id: nil)
    @no_property    = FactoryBot.build(:task, property_id: nil)
    @bad_status     = FactoryBot.build(:task, status: 'wrongThing')
    @bad_visibility = FactoryBot.build(:task, visibility: 4)
    @bad_priority   = FactoryBot.build(:task, priority: 'wrong thing')
    @completed_task = FactoryBot.build(:task, completed_at: Time.now - 1.hour)
    WebMock::RequestRegistry.instance.reset!
  end

  describe 'must be valid against the schema' do
    it 'in order to save' do
      expect(@task.save!(validate: false)).to eq true
      expect { @no_title.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { @no_creator.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { @no_owner.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { @no_property.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end
  end

  describe 'must be valid against the model' do
    it 'in order to save' do
      expect(@task.save!).to eq true
      expect { @no_title.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @no_creator.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @no_owner.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @no_property.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @bad_status.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @bad_visibility.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @bad_priority.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires uniqueness' do
    it 'on google_id' do
      @task.google_id = '12345678'
      @task.save
      duplicate = FactoryBot.build(:task, google_id: @task.google_id)

      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires booleans be in a state:' do
    let(:bad_license) { build :task, license_required: nil }
    let(:bad_needs_no_info) { build :task, needs_more_info: nil, due: Time.now + 3.hours, budget: Money.new(300_00), priority: 'low' }
    let(:bad_needs_info) { build :task, needs_more_info: nil }
    let(:bad_deleted) { build :task, deleted: nil }
    let(:bad_hidden) { build :task, hidden: nil }
    let(:bad_initilization) { build :task, initialization_template: nil }

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

    it 'deleted' do
      expect { bad_deleted.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_deleted.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'hidden' do
      expect { bad_hidden.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_hidden.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'initialization_template' do
      expect { bad_initilization.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_initilization.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'limits records by scope' do
    let(:initialization_template) { create :task, initialization_template: true }
    let(:has_good_info) { create :task, due: Time.now + 3.days, priority: 'medium', budget: 500 }

    let(:large_int) { create :task, position: '00000000091261646641' }
    let(:small_int) { create :task, position: '00000000000000046641' }

    it '#needs_more_info returns only non-initialization tasks where needs_more_info is false' do
      @task.save
      has_good_info.save
      initialization_template.save

      expect(Task.needs_more_info).to include @task
      expect(Task.needs_more_info).not_to include has_good_info
      expect(Task.needs_more_info).not_to include initialization_template
    end

    it '#in_process returns only non-initialization tasks where completed is nil' do
      @task.save
      @completed_task.save
      initialization_template.save

      expect(Task.in_process).to include @task
      expect(Task.in_process).not_to include @completed_task
      expect(Task.in_process).not_to include initialization_template
    end

    it '#complete returns only non-initialization tasks where completed is not nil' do
      @completed_task.save
      @task.save
      initialization_template.save

      expect(Task.complete).to include @completed_task
      expect(Task.complete).not_to include @task
      expect(Task.complete).not_to include initialization_template
    end

    it '#descending returns all records ordered by position_int' do
      large_int
      small_int
      expect(Task.descending).to eq [small_int, large_int]
    end
  end

  describe '#budget_remaining' do
    let(:no_budget) { create :task, cost: 250 }
    let(:no_cost) { create :task, budget: 250 }
    let(:both_moneys) { create :task, budget: 300, cost: 250 }

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

  describe '#assign_from_api_fields!' do
    it 'uses a json hash to assign record values' do
      task = Task.new
      task_json = JSON.parse(file_fixture('task_json_spec.json').read)

      expect(task.google_id).to eq nil
      expect(task.title).to eq nil
      expect(task.google_updated).to eq nil
      expect(task.parent_id).to eq nil
      expect(task.position).to eq nil
      expect(task.notes).to eq nil
      expect(task.due).to eq nil
      expect(task.completed_at).to eq nil

      task.assign_from_api_fields!(task_json)

      expect(task.google_id).not_to eq nil
      expect(task.title).not_to eq nil
      expect(task.google_updated).not_to eq nil
      expect(task.parent_id).not_to eq nil
      expect(task.position).not_to eq nil
      expect(task.notes).not_to eq nil
      expect(task.due).not_to eq nil
      expect(task.completed_at).not_to eq nil
    end
  end

  describe '#require_cost' do
    let(:complete_w_budget) { build :task, completed_at: Time.now, budget: 400 }
    let(:complete_w_both) { build :task, completed_at: Time.now, budget: 400, cost: 250 }

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
    let(:past_due) { build :task, due: Time.now - 1.hour }
    let(:future_due) { build :task, due: Time.now + 1.hour }

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

  describe '#decide_completeness' do
    let(:five_strikes)  { build :task }
    let(:four_strikes)  { build :task, budget: 50_00 }
    let(:three_strikes) { build :task, priority: 'medium', budget: 50_00 }
    let(:two_strikes)   { build :task, due: Time.now + 1.hour }
    let(:one_strike)    { build :task, due: Time.now + 1.hour, priority: 'medium' }
    let(:zero_strikes)  { build :task, due: Time.now + 1.hour, priority: 'medium', budget: 50_00 }

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

  describe '#sync_completed_fields' do
    let(:synced_not_complete) { create :task }
    let(:synced_complete) { create :task, completed_at: Time.now, status: 'completed' }
    let(:only_datetime) { build :task, completed_at: Time.now }
    let(:only_status) { build :task, status: 'completed' }

    it 'only fires when completed_at or status indicate completeness' do
      expect(synced_not_complete).not_to receive(:sync_completed_fields)
      synced_not_complete.save

      expect(synced_complete).to receive(:sync_completed_fields)
      synced_complete.save

      expect(only_status).to receive(:sync_completed_fields)
      only_status.save
    end

    it 'returns true if they are already in sync' do
      expect(synced_complete.send(:sync_completed_fields)).to eq true
    end

    it 'sets both fields to indicate completeness' do
      expect(only_status.completed_at).to eq nil
      only_status.save
      expect(only_status.completed_at).not_to eq nil

      expect(only_datetime.status).to eq 'needsAction'
      only_datetime.save
      expect(only_datetime.status).to eq 'completed'
    end
  end

  describe '#copy_position_as_integer' do
    let(:has_position) { build :task, position: '0000001234'}

    it 'only fires if position is present' do
      expect(@task).not_to receive(:copy_position_as_integer)
      @task.save!

      expect(has_position).to receive(:copy_position_as_integer)
      has_position.save!
    end

    it 'sets position_int field based upon position' do
      @task.save!
      expect(@task.reload.position).to eq nil
      expect(@task.position_int).to eq 0

      has_position.save!
      expect(has_position.reload.position).to eq '0000001234'
      expect(has_position.position_int).to eq 1234
    end
  end

  describe '#saved_changes_to_api_fields?' do
    let(:no_api_change) { create :task }
    let(:title_change) { create :task }
    let(:notes_change) { create :task }
    let(:due_change) { create :task }
    let(:status_change) { create :task }
    let(:deleted_change) { create :task }
    let(:completed_at_change) { create :task }
    let(:parent_change) { create :task }
    let(:new_user) { create :user }
    let(:new_property) { create :property }

    it 'returns false if no fields have changed' do
      no_api_change.tap do |t|
        t.priority = 'urgent'
        t.creator = new_user
        t.owner = new_user
        t.subject = new_user
        t.property = new_property
        t.budget = 167
        t.cost = 123
        t.visibility = 1
        t.license_required = true
        t.needs_more_info = true
        t.position = '00001234'
        t.initialization_template = true
        t.owner_type = 'Admin Staff'
      end
      no_api_change.save!

      expect(no_api_change.send(:saved_changes_to_api_fields?)).to eq false
    end

    it 'returns true if any API fields have changed' do
      title_change.update(title: 'New title')
      notes_change.update(notes: 'New notes content')
      due_change.update(due: Time.now + 2.weeks)
      status_change.update(status: 'complete')
      deleted_change.update(deleted: true)
      completed_at_change.update(completed_at: Time.now - 3.minutes)
      parent_change.update(parent_id: 'sOmEReallyLongAndRandomString')

      expect(title_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(notes_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(due_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(status_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(deleted_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(completed_at_change.send(:saved_changes_to_api_fields?)).to eq true
      expect(parent_change.send(:saved_changes_to_api_fields?)).to eq true
    end
  end

  describe '#create_with_api' do
    pending 'creates a task for the owner and creator'
  end

  describe '#update_with_api' do
    pending 'updates a task for the owner and creator'
  end
end
