# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Skill, type: :model do
  let(:skill) { build :skill }

  describe 'must be valid' do
    let(:no_name) { build :skill, name: nil }

    it 'in order to save' do
      expect(skill.save!).to eq true

      expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_name.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires booleans be in a state:' do
    let(:bad_license) { build :skill, license_required: nil }
    let(:bad_volunteerable) { build :skill, volunteerable: nil }

    it 'license_required' do
      expect { bad_license.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_license.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'volunteerable' do
      expect { bad_volunteerable.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_volunteerable.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  it 'requires name to be unique' do
    skill.save
    duplicate = FactoryBot.build(:skill, name: skill.name)

    expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
    expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
  end
end
