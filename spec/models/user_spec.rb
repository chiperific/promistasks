# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build :user }
  let(:no_name) { build :user, name: nil }
  let(:no_email) { build :user, email: nil }
  let(:no_password) { build :user, password: nil }
  let(:no_pw_or_conf) { build :user, password: nil, password_confirmation: nil }
  let(:no_encrypt_pw) { build :user, encrypted_password: nil }
  let(:token_expired) { create :oauth_user, oauth_expires_at: Time.now - 1.hour }
  let(:token_fresh) { create :oauth_user, oauth_expires_at: Time.now + 6.hours }
  let(:several_types) { create :user, program_staff: true, admin_staff: true, project_staff: true }
  let(:volunteer) { create :volunteer_user }

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
    it 'returns an array of types that describe the user' do
      expect(user.type).to eq ['Program Staff']
      expect(several_types.type).to eq ['Program Staff', 'Project Staff', 'Admin Staff']
      expect(volunteer.type).to eq ['Volunteer']
    end
  end

  describe 'self#from_omniauth' do
    it 'finds or creates a user based upon an authorization object' do
      raw_auth = JSON.parse(file_fixture('auth_spec.json').read)
      auth = OmniAuth::AuthHash.new(raw_auth)
      # in case the auth file has already been referenced
      User.where(oauth_id: auth.uid).delete_all

      # first run should add a new user
      expect { User.from_omniauth(auth) }.to(change { User.count })
      # second run shouldn't add a new User
      expect { User.from_omniauth(auth) }.not_to(change { User.count })
    end
  end

  describe '#refresh_token_if_expired' do
    it 'returns true if the token hasn\'t expired' do
      expect(token_fresh.refresh_token_if_expired).to eq true
    end

    it 'contacts Google for a new token if it\'s expired' do
      stub_request(:post, 'https://accounts.google.com/o/oauth2/token').to_return(body: 'You did it!', status: 200)

      token_expired.refresh_token_if_expired
      expect(WebMock).to have_requested(:post, 'https://accounts.google.com/o/oauth2/token')
    end

    it 'updates the user\'s oauth_token and oauth_expires_at' do
      return_json = { 'access_token': 'ya29.Gly7BRLVu0wJandalotlonger...',
                      'expires_in': 3600,
                      'id_token': 'eyJhbGciOiJSUzI1NiIsIandalotlonger...',
                      'token_type': 'Bearer' }

      stub_request(:post, 'https://accounts.google.com/o/oauth2/token').to_return(body: return_json.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })

      old_token = token_expired.oauth_token
      token_expired.refresh_token_if_expired

      expect(token_expired.oauth_token).not_to eq old_token
      expect(token_expired.oauth_token).to eq return_json[:access_token]
    end
  end

  describe '#token_expired?' do
    it 'returns true if oauth_expires_at is in the past' do
      expect(token_expired.token_expired?).to eq true
    end

    it 'returns false if oauth_expires_at is in the future' do
      expect(token_fresh.token_expired?).to eq false
    end
  end

  describe '#must_have_type' do
    let(:no_type) { build :user, program_staff: nil }

    it 'returns true if the user has at least one type' do
      expect(several_types.send(:must_have_type)).to eq true
      expect(volunteer.send(:must_have_type)).to eq true
    end

    it 'adds an error if the user has no types' do
      no_type.send(:must_have_type)
      expect(no_type.errors[:register_as]).to eq [': Must have at least one type.']
    end
  end

  describe '#clients_are_singular' do
    let(:client) { build :client_user }
    let(:client_and) { build :client_user, program_staff: true }

    it 'returns true if the user isn\'t a client' do
      expect(user.send(:clients_are_singular)).to eq true
    end

    it 'returns true if the user is only a client' do
      expect(client.send(:clients_are_singular)).to eq true
    end

    it 'adds an error if the user has been marked as more than just a client' do
      client_and.send(:clients_are_singular)
      expect(client_and.errors[:register_as]).to eq [': Clients can\'t have another type']
    end
  end

  describe '#only_one_deus_ex' do
    let(:deus_ex) { build :user, deus_ex_machina: true }
    let(:second_deus_ex) { build :user, deus_ex_machina: true }

    it 'returns true if deus_ex_machina is false' do
      expect(user.send(:only_one_deus_ex)).to eq true
    end

    it 'allows deus_ex_machina to remain true if no other user has been set as such' do
      expect(deus_ex.send(:only_one_deus_ex)).to eq true
      expect { deus_ex.save }.to(change { User.count })
    end

    it 'sets deus_ex_machina to false if a User.deus_ex_machina already exists' do
      deus_ex.save
      second_deus_ex.save
      expect(second_deus_ex.deus_ex_machina).to eq false
    end
  end
end
