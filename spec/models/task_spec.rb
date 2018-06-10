# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Task, type: :model do
  before :each do
    stub_request(:any, Constant::Regex::TASKLIST).to_return(
      headers: { 'Content-Type'=> 'application/json' },
      status: 200,
      body: FactoryBot.create(:tasklist_json).marshal_dump.to_json
    )
    stub_request(:any, Constant::Regex::TASK).to_return(
      headers: { 'Content-Type'=> 'application/json' },
      status: 200,
      body: FactoryBot.create(:task_json).marshal_dump.to_json
    )
    @creator        = FactoryBot.create(:oauth_user)
    @owner          = FactoryBot.create(:oauth_user)
    @property       = FactoryBot.create(:property)
    @task           = FactoryBot.build(:task, property: @property, creator: @creator, owner: @owner)
    @no_title       = FactoryBot.build(:task, property: @property, creator: @creator, owner: @owner, title: nil)
    @bad_priority   = FactoryBot.build(:task, property: @property, creator: @creator, owner: @owner, priority: 'wrong thing')
    @no_creator     = FactoryBot.build(:task, property: @property, owner: @owner, creator_id: nil)
    @no_owner       = FactoryBot.build(:task, property: @property, creator: @creator, owner_id: nil)
    @no_property    = FactoryBot.build(:task, property_id: nil, creator: @creator, owner: @owner)
    @bad_visibility = FactoryBot.build(:task, property: @property, creator: @creator, owner: @owner, visibility: 4)
    @completed_task = FactoryBot.build(:task, property: @property, creator: @creator, owner: @owner, completed_at: Time.now - 1.hour)
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
      expect { @bad_visibility.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { @bad_priority.save! }.to raise_error ActiveRecord::RecordInvalid
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
    let(:bad_initilization) { build :task, property: @property, creator: @creator, owner: @owner, initialization_template: nil }
    let(:bad_created)       { build :task, property: @property, creator: @creator, owner: @owner, created_in_api: nil }

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

    it 'initialization_template' do
      expect { bad_initilization.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_initilization.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'created_in_api' do
      expect { bad_created.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_created.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'limits records by scope' do
    let(:initialization_template) { create :task, property: @property, creator: @creator, owner: @owner, initialization_template: true }
    let(:has_good_info)           { create :task, property: @property, creator: @creator, owner: @owner, due: Time.now + 3.days, priority: 'medium', budget: 500 }
    let(:visibility_1)            { create :task, property: @property, creator: @creator, owner: @owner, visibility: 1 }
    let(:visibility_2)            { create :task, property: @property, creator: @creator, owner: @owner, visibility: 2 }

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

    it '#public_visible returns only undiscarded tasks where visibility is set to everyone' do
      visibility_1.save
      visibility_2.save
      @task.save

      expect(Task.public_visible).to include visibility_1
      expect(Task.public_visible).not_to include visibility_2
      expect(Task.public_visible).not_to include @task
    end

    pending '#related_to shows records where the user is the creator, owner or subject'
    pending '#visible_to shows a combo of #related_to and public_visible'
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

  describe '#assign_from_api_fields!' do
    it 'uses a json hash to assign record values' do
      task = Task.new
      task_json = JSON.parse(file_fixture('task_json_spec.json').read)

      expect(task.notes).to eq nil
      expect(task.due).to eq nil
      expect(task.completed_at).to eq nil

      task.assign_from_api_fields!(task_json)

      expect(task.notes).not_to eq nil
      expect(task.due).not_to eq nil
      expect(task.completed_at).not_to eq nil
    end
  end

  describe '#create_taskuser_for' do
    it 'doesn\'t make an API call if it already exists' do
      @task.save
      WebMock::RequestRegistry.instance.reset!
      @task.update(title: 'New title!')
      expect(WebMock).not_to have_requested(:post, Constant::Regex::TASK)
    end

    it 'makes an API call through TaskClient for the creator and owner' do
      @task.save
      expect(WebMock).to have_requested(:post, Constant::Regex::TASK).twice
    end

    it 'creates a task_user record for the creator and owner' do
      first_count = TaskUser.count
      @task.save
      expect(TaskUser.count).to eq first_count + 2
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

  describe '#prepare_for_api' do
    context 'when tasklists and task_users already exist' do
      it 'ensures tasklists exist for each user field' do
        @task.save
        first_count = Tasklist.count
        @task.update(title: 'New title!')
        expect(Tasklist.count).to eq first_count
      end
      it 'ensures task_users exist for each user field' do
        @task.save
        first_count = TaskUser.count
        @task.update(title: 'New title!')
        expect(TaskUser.count).to eq first_count
      end
    end
    context 'when tasklists and task_users don\'t exist' do
      it 'creates tasklists for each user field' do
        first_count = Tasklist.count
        @task.save
        expect(Tasklist.count).to eq first_count + 2
      end
      it 'creates task_users for each user field' do
        first_count = TaskUser.count
        @task.save
        expect(TaskUser.count).to eq first_count + 2
      end
    end
    context 'when the property has changed' do
      it 'ensures tasklists exist for the old property for each user field' do
        @task.save
        new_property = FactoryBot.create(:property)
        first_count = Tasklist.count
        @task.update(property: new_property)
        expect(Tasklist.count).to eq first_count + 2
      end
    end
  end

  describe '#create_with_api' do
    before :each do
      @new_task = FactoryBot.build(:task, property: @property, creator: @creator, owner: @owner)
      WebMock::RequestRegistry.instance.reset!
    end

    it 'creates a task for the owner and creator' do
      @new_task.save!
      expect(WebMock).to have_requested(:post, Constant::Regex::TASK).twice
    end
  end

  describe '#update_with_api' do
    before :each do
      @updated_task   = FactoryBot.create(:task, property: @property, creator: @creator, owner: @owner)
      @no_api_change  = FactoryBot.create(:task, property: @property, creator: @creator, owner: @owner)
      @new_user       = FactoryBot.create(:oauth_user, name: 'New user')
      @new_property   = FactoryBot.create(:property, name: 'New property', is_private: false, creator: @new_user)
      WebMock::RequestRegistry.instance.reset!
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
        t.initialization_template = true
        t.owner_type = 'Admin Staff'
      end
      expect(@no_api_change).not_to receive(:update_with_api)
      @no_api_change.save!
    end

    it 'updates the task for the owner and creator' do
      @updated_task.update(title: 'I have an updated title')
      expect(WebMock).to have_requested(:patch, Constant::Regex::TASK).twice
    end
  end

  describe '#relocate' do
    let(:updated_task)      { create :task, property: @property, creator: @creator, owner: @owner }
    let(:new_property_task) { create :task, property: @property, creator: @creator, owner: @owner }
    let(:new_property)      { create :property }

    it 'should only fire if the property changes' do
      updated_task.save!
      new_property_task.save!
      expect(updated_task).not_to receive(:relocate)
      updated_task.update(title: 'I won\'t relocate')

      expect(new_property_task).to receive(:relocate)
      new_property_task.update(property: new_property)
    end

    it 'relocates the task for the owner and creator' do
      new_property_task.save!
      WebMock::RequestRegistry.instance.reset!
      new_property_task.update(property: new_property, title: 'Move me!')
      expect(WebMock).to have_requested(:delete, Constant::Regex::TASK).twice
      expect(WebMock).to have_requested(:post, Constant::Regex::TASK).twice
    end
  end
end
