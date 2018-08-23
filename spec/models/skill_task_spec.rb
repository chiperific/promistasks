# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SkillTask, type: :model do
  before :each do
    @task = create(:task)
    @skill_task = build(:skill_task, task: @task)
    WebMock.reset_executed_requests!
  end

  describe 'must be valid' do
    let(:no_skill) { build :skill_task, task: @task, skill_id: nil }
    let(:no_task) { build :skill_task, task_id: nil }

    it 'in order to save' do
      expect(@skill_task.save!).to eq true

      expect { no_skill.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_skill.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { no_task.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_task.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  it 'can\'t duplicate skill and task' do
    @skill_task.save
    duplicate = build(:skill_task, skill: @skill_task.skill, task: @skill_task.task)

    expect { duplicate.save! }.to raise_error ActiveRecord::RecordNotUnique
  end
end
