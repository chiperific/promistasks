# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SkillUser, type: :model do
  let(:skill_user) { build :skill_user }

  describe 'must be valid' do
    let(:no_skill) { build :skill_user, skill_id: nil }
    let(:no_user) { build :skill_user, user_id: nil }

    it 'in order to save' do
      expect(skill_user.save!).to eq true

      expect { no_skill.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_user.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_skill.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { no_user.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  it 'can\'t duplicate skill and user' do
    skill_user.save

    skill = skill_user.skill
    user = skill_user.user

    duplicate = build(:skill_user, skill_id: skill.id, user_id: user.id)

    expect { duplicate.save! }.to raise_error ActiveRecord::RecordNotUnique
  end

  describe 'requires booleans be in a state:' do
    let(:bad_licensed) { build :skill_user, is_licensed: nil }

    it 'is_licensed' do
      expect { bad_licensed.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end
end
