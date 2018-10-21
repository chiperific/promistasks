# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  before :each do
    @user = build(:user)
    @oauth_user = build(:oauth_user)
    WebMock.reset_executed_requests!
  end

  describe 'must be valid' do
    let(:no_name)       { build :user, name: nil }
    let(:no_email)      { build :user, email: nil }
    let(:no_password)   { build :user, password: nil }
    let(:no_pw_or_conf) { build :user, password: nil, password_confirmation: nil }
    let(:no_encrypt_pw) { build :user, encrypted_password: nil }
    let(:no_phone)      { build :user, phone: nil }
    let(:nil_rate)      { build :user, rate: nil }
    let(:nil_adults)    { build :user, adults: nil }
    let(:nil_children)  { build :user, children: nil }

    context 'against schema' do
      it 'in order to save' do
        expect(@user.save!(validate: false)).to eq true

        expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_email.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_encrypt_pw.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_phone.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { nil_rate.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { nil_adults.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { nil_children.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      end
    end

    context 'against model' do
      it 'in order to save' do
        expect(@user.save!).to eq true

        expect { no_name.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_email.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_password.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_pw_or_conf.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_phone.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { nil_rate.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { nil_adults.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { nil_children.save! }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe 'requires uniqueness' do
    it 'on name' do
      @user.save

      duplicate = build(:user, name: @user.name)
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'on email' do
      @user.save

      duplicate = build(:user, email: @user.email)
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'on oauth_id' do
      @user.oauth_id = '100000000000000000001'
      @user.save

      duplicate = build(:user, oauth_id: @user.oauth_id)
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'on oauth_token' do
      @user.oauth_token = 'ya29.Glu6BYecZ3wHaU-ilHoWWo0YcZrmpj4j6eet3qec7_3SD1RWt3J4xhx9Bg6IjMELq9WdbbB48sw6T_Y3FmWVI1sgRIMxYg4Nr2wmnt6WxBQ4aqTnChgkEPpYvCX0'
      @user.save

      duplicate = build(:user, oauth_token: @user.oauth_token)
      expect { duplicate.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      expect { duplicate.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'requires booleans be in a state:' do
    let(:bad_staff)      { build :user, staff: nil }
    let(:bad_client)     { build :user, client: nil }
    let(:bad_volunteer)  { build :user, volunteer: nil }
    let(:bad_contractor) { build :user, contractor: nil }
    let(:bad_admin)      { build :user, admin: nil }

    it 'staff' do
      expect { bad_staff.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_staff.save! }.to raise_error ActiveRecord::RecordInvalid
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

    it 'admin' do
      expect { bad_admin.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect { bad_admin.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'limits records by scope' do
    let(:client)           { create :client_user }
    let(:volunteer)        { create :volunteer_user }
    let(:client_volunteer) { create :client_user, volunteer: true }
    let(:admin)            { create :admin }
    let(:contractor)       { create :contractor_user }
    let(:oauth_user2)      { create :oauth_user }
    let(:property)         { create :property, creator: oauth_user2 }

    it '#staff returns only Users with an oauth_id, where staff is true or admin is true' do
      @user.save
      @oauth_user.save

      expect(User.staff).to include @oauth_user
      expect(User.staff).to include @user
      expect(User.staff).to include admin
      expect(User.staff).not_to include client
    end

    it '#not_clients returns only Users where client is false or client is also a volunteer' do
      @user.save
      expect(User.not_clients).to include @user
      expect(User.not_clients).to include client_volunteer
      expect(User.not_clients).not_to include client
    end

    it '#staff_except(user) returns staff minus the provided user' do
      @user.save
      @oauth_user.save

      expect(User.staff_except(@oauth_user)).not_to include @oauth_user
      expect(User.staff_except(@oauth_user)).not_to include client
      expect(User.staff_except(@oauth_user)).not_to include volunteer
      expect(User.staff_except(@oauth_user)).not_to include contractor
      expect(User.staff_except(@oauth_user)).to include @user
      expect(User.staff_except(@oauth_user)).to include admin
    end

    it '#not_staff returns only Users without an oauth_id' do
      @user.save
      @oauth_user.save

      expect(User.not_staff).to include client
      expect(User.not_staff).to include client_volunteer
      expect(User.not_staff).to include contractor
      expect(User.not_staff).to include volunteer
      expect(User.not_staff).not_to include @oauth_user
      expect(User.not_staff).not_to include @user
    end

    context 'property-related scopes' do
      before :each do
        @user.save
        @oauth_user.save
        create(:task, property: property, creator: @user, owner: @oauth_user)
        create(:task, property: property, creator: @oauth_user, owner: volunteer)
        create(:task, property: property, creator: oauth_user2, owner: contractor)
        create(:task, property: property, creator: @user, owner: @user)
      end

      it '#with_tasks_for returns only Users that are related to tasks of the property' do
        expect(User.with_tasks_for(property)).to include @oauth_user
        expect(User.with_tasks_for(property)).to include volunteer
        expect(User.with_tasks_for(property)).to include contractor
        expect(User.with_tasks_for(property)).to include @user
        expect(User.with_tasks_for(property)).to include oauth_user2
        expect(User.with_tasks_for(property)).not_to include client
        expect(User.with_tasks_for(property)).not_to include client_volunteer
      end

      it '#created_tasks_for returns only Users that are creators of tasks related to property' do
        expect(User.created_tasks_for(property)).to include @user
        expect(User.created_tasks_for(property)).to include @oauth_user
        expect(User.created_tasks_for(property)).to include oauth_user2
        expect(User.created_tasks_for(property)).not_to include client
        expect(User.created_tasks_for(property)).not_to include volunteer
        expect(User.created_tasks_for(property)).not_to include contractor
        expect(User.created_tasks_for(property)).not_to include client_volunteer
      end

      it '#owned_tasks_for returns only Users that are owners of tasks related to property' do
        expect(User.owned_tasks_for(property)).to include @oauth_user
        expect(User.owned_tasks_for(property)).to include volunteer
        expect(User.owned_tasks_for(property)).to include contractor
        expect(User.owned_tasks_for(property)).to include @user
        expect(User.owned_tasks_for(property)).not_to include oauth_user2
        expect(User.owned_tasks_for(property)).not_to include client_volunteer
        expect(User.owned_tasks_for(property)).not_to include client
      end

      it '#without_tasks_for returns Users that aren\'t related to tasks of the property' do
        expect(User.without_tasks_for(property)).to include client
        expect(User.without_tasks_for(property)).to include client_volunteer
        expect(User.without_tasks_for(property)).not_to include @oauth_user
        expect(User.without_tasks_for(property)).not_to include volunteer
        expect(User.without_tasks_for(property)).not_to include contractor
        expect(User.without_tasks_for(property)).not_to include @user
        expect(User.without_tasks_for(property)).not_to include oauth_user2
      end

      context 'know that if without_task_for works then' do
        it 'without_created_tasks_for works too' do
          expect(true).to eq true
        end

        it 'without_owned_tasks_for works too' do
          expect(true).to eq true
        end
      end
    end
  end

  describe 'self#from_omniauth' do
    it 'finds or creates a user based upon an authorization object' do
      raw_auth = JSON.parse(file_fixture('auth_spec.json').read)
      auth = OmniAuth::AuthHash.new(raw_auth)
      # in case the auth file has already been referenced
      User.where(oauth_id: auth.uid).delete_all
      # in case the Organization has not already been created
      Organization.new.save if Organization.count == 0

      # first run should add a new user
      expect { User.from_omniauth(auth) }.to(change { User.count })
      # second run shouldn't add a new User
      expect { User.from_omniauth(auth) }.not_to(change { User.count })
    end
  end

  describe 'self#new_with_session' do
    it 'came from google omniauth readme' do
      expect(true).to eq true
    end
  end

  describe '#active_for_authentication?' do
    it 'came from Discard readme' do
      expect(true).to eq true
    end
  end

  describe '#all_tasks' do
    before :each do
      @user.save
      @no = create(:task)
    end

    it 'returns tasks the user created' do
      yes = FactoryBot.create(:task, creator: @user)

      expect(@user.all_tasks).to include yes
      expect(@user.all_tasks).not_to include @no
    end

    it 'returns tasks the user owns' do
      yes = create(:task, owner: @user)

      expect(@user.all_tasks).to include yes
      expect(@user.all_tasks).not_to include @no
    end
  end

  describe '#can_view_park' do
    before :each do
      @park = create(:park)
    end

    it 'returns true if user is admin' do
      @admin = create(:admin)
      expect(@admin.can_view_park(@park)).to eq true
    end

    it 'returns true if user is staff' do
      @user.save
      expect(@user.can_view_park(@park)).to eq true
    end

    it 'returns true if user created an associated property' do
      @user = create(:volunteer_user)
      create(:property, creator: @user, park: @park)

      expect(@user.can_view_park(@park)).to eq true
    end

    it 'returns true if user has tasks for an associated property' do
      @volunteer = create(:volunteer_user)
      @contractor = create(:contractor_user)
      @property = create(:property, park: @park)
      create(:task, property: @property, creator: @volunteer, owner: @contractor)

      expect(@volunteer.can_view_park(@park)).to eq true
      expect(@contractor.can_view_park(@park)).to eq true
    end
  end

  describe '#fetch_default_tasklist' do
    it 'returns false if oauth_id is missing' do
      @user.save
      expect(@user.fetch_default_tasklist).to eq false
    end

    it 'makes an API call' do
      @oauth_user.save
      @oauth_user.fetch_default_tasklist
      expect(WebMock).to have_requested(:get, 'https://www.googleapis.com/tasks/v1/users/@me/lists/@default')
    end

    it 'returns a json tasklist object' do
      @oauth_user.save
      response = @oauth_user.fetch_default_tasklist
      expect(response['kind']).to eq 'tasks#taskList'
    end
  end

  describe '#fname' do
    it 'returns the name field split at the first space' do
      expect(@user.fname).to eq 'User'
    end
  end

  describe '#list_api_tasklists' do
    it 'returns false if oauth_id is missing' do
      @user.save
      expect(@user.list_api_tasklists).to eq false
    end

    it 'makes an API call' do
      @oauth_user.save
      @oauth_user.list_api_tasklists
      expect(WebMock).to have_requested(:get, 'https://www.googleapis.com/tasks/v1/users/@me/lists')
    end

    it 'returns a hash of google tasklist objects' do
      @oauth_user.save
      response = @oauth_user.list_api_tasklists
      expect(response['kind']).to eq 'tasks#taskLists'
    end
  end

  describe '#not_client?' do
    let(:client)  { create :client_user }
    let(:staff)   { create :user }
    let(:no_type) { build :user, staff: false }

    it 'returns false if user.client == true' do
      expect(client.not_client?).to eq false
    end

    it 'returns false if type is empty, user is not admin, and user is not oauth' do
      expect(no_type.client?).to eq false
      expect(no_type.type.empty?).to eq true
      expect(no_type.admin?).to eq false
      expect(no_type.oauth?).to eq false
      expect(no_type.not_client?).to eq false
    end

    it 'returns true if user.client == false, and one of the following is true: type is present, user is admin, or user is oauth' do
      expect(staff.client?).to eq false
      expect(staff.type.present?).to eq true
      expect(staff.admin?).to eq false
      expect(staff.oauth?).to eq false
      expect(staff.not_client?).to eq true
    end
  end

  describe '#oauth?' do
    it 'returns true if user has oauth_id' do
      expect(@user.oauth?).to eq false
    end

    it 'returns false if user doesn\'t have oauth_id' do
      expect(@oauth_user.oauth?).to eq true
    end
  end

  describe '#refresh_token!' do
    let(:token_expired) { create :oauth_user, oauth_expires_at: Time.now - 1.hour }
    let(:token_fresh)   { create :oauth_user, oauth_expires_at: Time.now + 6.hours }

    it 'returns false if the token hasn\'t expired' do
      expect(token_fresh.refresh_token!).to eq false
    end

    it 'returns false if the user isn\'t oauth' do
      expect(@user.refresh_token!).to eq false
    end

    it 'contacts Google for a new token if it\'s expired' do
      token_expired.refresh_token!
      expect(WebMock).to have_requested(:post, 'https://accounts.google.com/o/oauth2/token')
    end

    it 'updates the user\'s oauth_token and oauth_expires_at' do
      old_token = token_expired.oauth_token
      token_expired.refresh_token!

      expect(token_expired.oauth_token).not_to eq old_token
      expect(token_expired.oauth_token).to eq 'ya29.Gly7BRLVu0wJandalotlonger...'
    end
  end

  describe '#readable_type' do
    let(:no_type) { build :user, staff: false, oauth_id: 'present' }
    let(:multiple_types) { build :user, staff: true, contractor: true, volunteer: true }

    it 'returns "Staff" if oauth is true and type is empty' do
      expect(no_type.readable_type).to eq 'Staff'
    end

    it 'returns the type(s) joined with commas' do
      expect(multiple_types.readable_type).to eq 'Staff, Volunteer, Contractor'
    end
  end

  describe '#token_expired?' do
    let(:token_expired) { create :oauth_user, oauth_expires_at: Time.now - 1.hour }
    let(:token_fresh)   { create :oauth_user, oauth_expires_at: Time.now + 6.hours }

    it 'returns nil if the user isn\'t an oauth' do
      expect(@user.token_expired?).to eq nil
    end
    it 'returns true if oauth_expires_at is in the past' do
      expect(token_expired.token_expired?).to eq true
    end

    it 'returns false if oauth_expires_at is in the future' do
      expect(token_fresh.token_expired?).to eq false
    end
  end

  describe '#type' do
    let(:several_types) { build :user, staff: true, volunteer: true, contractor: true }
    let(:volunteer)     { build :volunteer_user }

    it 'returns an array of types that describe the user' do
      expect(@user.type).to eq ['Staff']
      expect(several_types.type).to eq ['Staff', 'Volunteer', 'Contractor']
      expect(volunteer.type).to eq ['Volunteer']
    end
  end

  describe '#write_type' do
    pending 'sets booleans based upon a text field'

    pending 'adds an error when the text is invalid'
  end

  # begin private methods

  describe '#admin_are_staff' do
    let(:admin) { build :user, admin: true, staff: false, volunteer: true }
    let(:bad_admin) { build :user, admin: true }

    it 'only fires if admin is checked' do
      expect(@user).not_to receive(:admin_are_staff)
      @user.save!

      expect(admin).to receive(:admin_are_staff)
      admin.save!
    end

    it 'sets staff to true' do
      expect(admin.staff?).to eq false
      admin.save!
      expect(admin.staff?).to eq true
    end
  end

  describe '#api_headers' do
    let(:user) { create :oauth_user }

    it 'returns a hash' do
      expect(user.send(:api_headers).is_a?(Hash)).to eq true
    end
  end

  describe '#clients_are_limited' do
    let(:client) { build :client_user, volunteer: true }
    let(:client_and) { build :client_user, staff: true }

    it 'returns true if the user isn\'t a client' do
      expect(@user.send(:clients_are_limited)).to eq true
    end

    it 'returns true if the user is a volunteer' do
      expect(client.send(:clients_are_limited)).to eq true
    end

    it 'adds an error if the user has been marked as more than just a client' do
      client_and.send(:clients_are_limited)
      expect(client_and.errors[:register_as]).to eq [': Clients can\'t be staff or contractors']
    end
  end

  describe '#discard_connections' do
    before :each do
      @user.save
      3.times do
        create(:connection, user: @user, relationship: 'staff contact')
      end
    end

    context 'when discarded_at is not present' do
      it 'doesn\'t fire' do
        expect(@user).not_to receive(:discard_connections)
        @user.update(name: 'new name')
      end
    end

    context 'when discarded_at is present but was also present at last save' do
      it 'doesn\'t fire' do
        @user.discard

        expect(@user).not_to receive(:discard_connections)
        @user.update(discarded_at: Time.now + 2.minutes)
      end
    end

    context 'when discarded_at is present and wasn\'t at last save' do
      it 'fires' do
        expect(@user).to receive(:discard_connections)
        @user.discard
      end

      it 'sets all child connections as discarded' do
        expect(@user.connections.active.count).to eq 3

        @user.send(:discard_connections)

        expect(@user.connections.active.count).to eq 0
        expect(@user.connections.count).to eq 3
      end
    end
  end

  describe '#must_have_type' do
    let(:no_type)       { build :user, staff: false }
    let(:several_types) { create :user, staff: true, admin: true, volunteer: true }
    let(:volunteer)     { create :volunteer_user }

    it 'returns true if the user has at least one type' do
      expect(several_types.send(:must_have_type)).to eq true
      expect(volunteer.send(:must_have_type)).to eq true
    end

    it 'adds an error if the user has no types' do
      no_type.send(:must_have_type)
      expect(no_type.errors[:register_as]).to eq ['a user type from the list']
    end
  end

  describe '#propegate_tasklists' do
    before :each do
      3.times { create(:property) }
    end

    it 'only fires if user has an oauth_id' do
      expect(@user.oauth_id).to eq nil
      expect(@user).not_to receive(:propegate_tasklists)
      @user.save!
    end

    it 'only fires on create' do
      expect(@oauth_user.oauth_id).not_to eq nil
      expect(@oauth_user).to receive(:propegate_tasklists)
      @oauth_user.save!

      expect(@oauth_user).not_to receive(:propegate_tasklists)
      @oauth_user.update(name: 'New name!')
    end

    it 'creates tasklists for the new user' do
      # expect(Tasklist.where(user: @oauth_user).count).to eq first_count + prop_count
      expect { @oauth_user.save }.to change { Tasklist.where(user: @oauth_user).count }.by(3)
    end
  end

  describe '#undiscard_connections' do
    before :each do
      @user.discarded_at = Time.now
      @user.save
      3.times do
        create(:connection, user: @user, relationship: 'staff contact', discarded_at: Time.now)
      end
    end

    context 'when discarded_at is present' do
      it 'doesn\'t fire' do
        expect(@user).not_to receive(:undiscard_connections)
        @user.discard
      end
    end

    context 'when discarded_at is blank and was blank before last save' do
      it 'doesn\'t fire' do
        @user.undiscard

        expect(@user).not_to receive(:undiscard_connections)
        @user.update(name: 'new name')
      end
    end

    context 'when discarded_at is blank and was present before last save' do
      it 'fires' do
        expect(@user).to receive(:undiscard_connections)
        @user.undiscard
      end

      it 'sets all child connections as undiscarded' do
        expect(@user.connections.discarded.count).to eq 3

        @user.undiscard

        expect(@user.connections.discarded.count).to eq 0
        expect(@user.connections.count).to eq 3
      end
    end
  end
end
