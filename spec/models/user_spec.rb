# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build :user }
  let(:no_name) { build :user, name: nil }
  let(:no_email) { build :user, email: nil }
  let(:no_password) { build :user, password: nil }
  let(:no_pw_or_conf) { build :user, password: nil, password_confirmation: nil }
  let(:no_encrypt_pw) { build :user, encrypted_password: nil }

  describe 'must be valid against schema' do
    it 'in order to save' do
      expect(user.save!(validate: false)).to eq true

      expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_email.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { no_encrypt_pw.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
    end
  end

  describe 'must be valid against model' do
    it 'in order to save' do
      expect(user.save!).to eq true

      expect { no_name.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { no_email.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { no_password.save! }.to raise_error ActiveRecord::RecordInvalid
      expect { no_pw_or_conf.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires uniqueness' do
    it 'on name' do
      user.save

      duplicate = FactoryBot.build(:user, name: user.name)
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'on email' do
      user.save

      duplicate = FactoryBot.build(:user, email: user.email)
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'on oauth_id' do
      user.oauth_id = '100000000000000000001'
      user.save

      duplicate = FactoryBot.build(:user, oauth_id: user.oauth_id)
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'on oauth_token' do
      user.oauth_token = 'ya29.Glu6BYecZ3wHaU-ilHoWWo0YcZrmpj4j6eet3qec7_3SD1RWt3J4xhx9Bg6IjMELq9WdbbB48sw6T_Y3FmWVI1sgRIMxYg4Nr2wmnt6WxBQ4aqTnChgkEPpYvCX0'
      user.save

      duplicate = FactoryBot.build(:user, oauth_token: user.oauth_token)
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires booleans be in a state:' do
    let(:bad_program_staff) { build :user, program_staff: nil }
    let(:bad_project_staff) { build :user, project_staff: nil }
    let(:bad_admin_staff)   { build :user, admin_staff: nil }
    let(:bad_client)        { build :user, client: nil }
    let(:bad_volunteer)     { build :user, volunteer: nil }
    let(:bad_contractor)    { build :user, contractor: nil }
    let(:bad_system_admin)  { build :user, system_admin: nil }
    let(:bad_deus_ex)       { build :user, deus_ex_machina: nil }

    it 'program_staff' do
      expect { bad_program_staff.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_program_staff.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'project_staff' do
      expect { bad_project_staff.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_project_staff.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'admin_staff' do
      expect { bad_admin_staff.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_admin_staff.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'client' do
      expect { bad_client.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_client.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'volunteer' do
      expect { bad_volunteer.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_volunteer.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'contractor' do
      expect { bad_contractor.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_contractor.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'system_admin' do
      expect { bad_system_admin.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_system_admin.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'deus_ex_machina' do
      expect { bad_deus_ex.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_deus_ex.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'limits records by scope' do
    let(:deus_ex) { create :user, deus_ex_machina: true }
    let(:oauth_user) { create :user, oauth_id: '100000000000000000001' }

    it '#staff returns only non-deus-ex Users with an oauth_id' do
      user.save
      oauth_user.save
      deus_ex.save

      expect(User.staff).to include oauth_user
      expect(User.staff).not_to include user
      expect(User.staff).not_to include deus_ex
    end

    it '#not_staff returns only non-deus-ex Users without an oauth_id' do
      user.save
      oauth_user.save
      deus_ex.save

      expect(User.not_staff).to include user
      expect(User.not_staff).not_to include oauth_user
      expect(User.not_staff).not_to include deus_ex
    end

    it '#deus_ex_machina returns the first User marked as such' do
      user.save
      oauth_user.save
      deus_ex.save

      expect(User.deus_ex_machina).to include deus_ex
      expect(User.deus_ex_machina).not_to include user
      expect(User.deus_ex_machina).not_to include oauth_user
    end
  end

  describe '#type' do
    pending 'returns an array of types that describe the user'
  end

  describe '#from_omniauth' do
    pending 'finds or creates a user based upon an authorization object'

    pending 'updates the oauth_token and oauth_refresh_token'

    pending 'returns a user record'
  end

  describe '#new_with_session' do
    pending 'ensures the user\'s email is set when RegistrationsController builds a resource'
  end

  describe '#refresh_token_if_expired' do
    pending 'returns true if the token hasn\'t expired'

    pending 'contacts Google for a new token if it\'s expired'

    pending 'updates the user\'s oauth_token and oauth_expires_at'
  end

  describe '#token_expired?' do
    pending 'returns true if oauth_expires_at is in the past'

    pending 'returns false if oauth_expires_at is in the future'
  end

  describe '#must_have_type' do
    pending 'returns true if the user has at least one type'

    pending 'adds an error if the user has no types'
  end

  describe '#only_one_deus_ex' do
    pending 'returns true if deus_ex_machina is false'

    pending 'allows deus_ex_machina to remain true if no other user has been set as such'

    pending 'sets deus_ex_machina to false if a User.deus_ex_machina already exists'
  end
end
