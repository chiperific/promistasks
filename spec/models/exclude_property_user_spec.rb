# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExcludePropertyUser, type: :model do
  let(:exclude_property_user) { build :exclude_property_user }

  describe 'must be valid' do
    let(:no_property) { build :exclude_property_user, property_id: nil }
    let(:no_user) { build :exclude_property_user, user_id: nil }
    it 'in order to save' do
      stub_request(:any, Constant::Regex::TASKLIST).to_return(body: 'You did it!', status: 200)
      expect(exclude_property_user.save!).to eq true

      expect { no_property.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_user.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation

      expect { no_property.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { no_user.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  it 'can\'t duplicate property and user' do
    stub_request(:any, Constant::Regex::TASKLIST).to_return(body: 'You did it!', status: 200)
    exclude_property_user.save

    property = exclude_property_user.property
    user = exclude_property_user.user

    duplicate = FactoryBot.build(:exclude_property_user, property_id: property.id, user_id: user.id)

    expect { duplicate.save! }.to raise_error ActiveRecord::RecordNotUnique
  end
end
