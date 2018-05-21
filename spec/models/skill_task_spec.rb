# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SkillTask, type: :model do
  let(:skill_task) { build :skill_task }

  describe 'must be valid' do
    let(:no_skill) { build :skill_task, skill_id: nil }
    let(:no_task) { build :skill_task, task_id: nil }

    it 'in order to save' do
      stub_request(:any, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).to_return(body: 'You did it!', status: 200)
      expect(skill_task.save!).to eq true

      expect { no_skill.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_skill.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { no_task.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_task.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  it 'can\'t duplicate skill and task' do
    stub_request(:any, %r/https:\/\/www.googleapis.com\/tasks\/v1\/users\/@me\/lists(\/||)\w{0,130}/).to_return(body: 'You did it!', status: 200)
    skill_task.save

    skill = skill_task.skill
    task = skill_task.task

    duplicate = FactoryBot.build(:skill_task, skill_id: skill.id, task_id: task.id)

    expect { duplicate.save! }.to raise_error ActiveRecord::RecordNotUnique
  end
end
