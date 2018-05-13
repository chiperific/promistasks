# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Task, type: :model do
  let(:task) { build :task }

  let(:no_title) { build :task, title: nil }
  let(:no_creator) { build :task, creator_id: nil }
  let(:no_owner) { build :task, owner_id: nil }

  let(:completed_task) { build :task, completed_at: Time.now - 1.hour }

  describe 'must be valid against the schema' do
    it 'in order to save' do
      expect(task.save!(validate: false)).to eq true
      expect { no_title.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_creator.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_owner.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end
  end

  describe 'must be valid against the model' do
    it 'in order to save' do
      expect(task.save!).to eq true
      expect { no_title.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { no_creator.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { no_owner.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires uniqueness' do
    it 'on google_id' do
      task.google_id = '12345678'
      task.save
      duplicate = FactoryBot.build(:task, google_id: task.google_id)

      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'on position' do
      task.position = '00001234'
      task.save
      duplicate = FactoryBot.build(:task, position: task.position)

      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'on title' do
      task.save
      duplicate = FactoryBot.build(:task, title: task.title)

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
      # before_save :decide_completeness potects the state
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

    it '#needs_more_info returns only non-initialization tasks where needs_more_info is false' do
      task.save
      has_good_info.save
      initialization_template.save

      expect(Task.needs_more_info).to include task
      expect(Task.needs_more_info).not_to include has_good_info
      expect(Task.needs_more_info).not_to include initialization_template
    end

    it '#in_process returns only non-initialization tasks where completed is nil' do
      task.save
      completed_task.save
      initialization_template.save

      expect(Task.in_process).to include task
      expect(Task.in_process).not_to include completed_task
      expect(Task.in_process).not_to include initialization_template
    end

    it '#complete returns only non-initialization tasks where completed is not nil' do
      completed_task.save
      task.save
      initialization_template.save

      expect(Task.complete).to include completed_task
      expect(Task.complete).not_to include task
      expect(Task.complete).not_to include initialization_template
    end
  end

  describe '#budget_remaining' do
    let(:no_budget) { create :task, cost: 250 }
    let(:no_cost) { create :task, budget: 250 }
    let(:both_moneys) { create :task, budget: 300, cost: 250 }

    it 'returns nil if budget && cost are both nil' do
      task.save

      expect(task.budget_remaining).to eq nil
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

  describe '#require_cost' do
    let(:complete_w_budget) { build :task, completed_at: Time.now, budget: 400 }
    let(:complete_w_both) { build :task, completed_at: Time.now, budget: 400, cost: 250 }

    it 'ignores tasks that aren\'t complete' do
      task.save
      expect(task.errors[:cost].empty?).to eq true
    end

    it 'ignores tasks where budget isn\'t present' do
      completed_task.save
      expect(completed_task.errors[:cost].empty?).to eq true
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
      task.save
      expect(task.errors[:due].empty?).to eq true
    end

    it 'adds an error if due is in the past' do
      past_due.save
      expect(past_due.errors[:due]).to eq ["must be in the future"]
    end

    it 'returns true if due is in the future' do
      future_due.save
      expect(future_due.errors[:due].empty?).to eq true
    end
  end

  describe '#decide_completeness' do
    let(:nine_strikes)  { build :task }
    let(:eight_strikes) { build :task, property_id: 1 }
    let(:seven_strikes) { build :task, budget: 50_00 }
    let(:six_strikes)   { build :task, property_id: 1, budget: 50_00 }
    let(:five_strikes)  { build :task, priority: 'medium', budget: 50_00 }
    let(:four_strikes)  { build :task, due: Time.now + 1.hour, property_id: 1 }
    let(:three_strikes) { build :task, due: Time.now + 1.hour, budget: 50_00 }
    let(:two_strikes)   { build :task, due: Time.now + 1.hour, budget: 50_00, property_id: 1 }
    let(:one_strike)    { build :task, due: Time.now + 1.hour, budget: 50_00, priority: 'medium' }
    let(:zero_strikes)  { build :task, due: Time.now + 1.hour, budget: 50_00, priority: 'medium', property_id: 1 }

    it 'sets needs_more_info based on strikes' do
      expect(nine_strikes.needs_more_info).to eq false
      expect(eight_strikes.needs_more_info).to eq false
      expect(seven_strikes.needs_more_info).to eq false
      expect(six_strikes.needs_more_info).to eq false
      expect(five_strikes.needs_more_info).to eq false
      expect(four_strikes.needs_more_info).to eq false
      expect(three_strikes.needs_more_info).to eq false
      expect(two_strikes.needs_more_info).to eq false
      expect(one_strike.needs_more_info).to eq false
      expect(zero_strikes.needs_more_info).to eq false

      nine_strikes.save
      eight_strikes.save
      seven_strikes.save
      six_strikes.save
      five_strikes.save
      four_strikes.save
      three_strikes.save
      two_strikes.save
      one_strike.save
      zero_strikes.save

      expect(nine_strikes.needs_more_info).to eq true
      expect(eight_strikes.needs_more_info).to eq true
      expect(seven_strikes.needs_more_info).to eq true
      expect(six_strikes.needs_more_info).to eq true
      expect(five_strikes.needs_more_info).to eq true
      expect(four_strikes.needs_more_info).to eq true
      expect(three_strikes.needs_more_info).to eq false
      expect(two_strikes.needs_more_info).to eq false
      expect(one_strike.needs_more_info).to eq false
      expect(zero_strikes.needs_more_info).to eq false
    end
  end

  describe '#api_fields_changed?' do
    pending 'returns false if no fields have changed'

    pending 'returns true if any API fields have changed'
  end

  describe '#create_with_api' do
    pending 'creates a task for the owner and creator'
  end

  describe '#update_with_api' do
    pending 'updates a task for the owner and creator'
  end
end
