# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Park, type: :model do
  describe 'must be valid' do
    let(:park) { build :park }
    let(:no_name) { build :park, name: nil }

    describe 'against the schema' do
      it 'in order to save' do
        expect { park.save!(validate: false) }.not_to raise_error
        expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      end
    end

    describe 'against the model' do
      it 'in order to save' do
        expect { park.save! }.not_to raise_error
        expect { no_name.save! }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe 'requires uniqueness on name' do
    before :each do
      @park = create(:park)
      @dup_name = build(:park, name: @park.name)
    end

    it 'in the schema' do
      expect { @dup_name.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
    end

    it 'in the model' do
      expect { @dup_name.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe 'limits records by scope' do
    pending '#created_since'
  end

  describe '#address_has_changed?' do
    let(:park) { create :park, address: 'address' }

    it 'returns false if #address was removed' do
      park.address = nil
      expect(park.address_has_changed?).to eq false
    end

    it 'returns true if #address changed' do
      park.address = 'new address'
      expect(park.address_has_changed?).to eq true
    end

    it 'returns true if #city changed' do
      park.city = 'new city'
      expect(park.address_has_changed?).to eq true
    end

    it 'returns true if #state changed' do
      park.state = 'ns'
      expect(park.address_has_changed?).to eq true
    end

    it 'returns true if #postal_code changed' do
      park.postal_code = '12345'
      expect(park.address_has_changed?).to eq true
    end

    it 'returns false if none of the address fields have changed' do
      park.notes = 'just updated the notes'
      expect(park.address_has_changed?).to eq false
    end
  end

  describe '#cascade_discard' do
    let(:park) { create :park }

    context 'when discarded_at is present and was not present in last save' do
      let(:park_user) { create :park_user, park: park }
      let(:payment) { create :payment, park: park }

      it 'fires' do
        expect(park).to receive(:cascade_discard)
        park.discard
      end

      it 'deletes all associated park_user records' do
        park_user
        payment

        expect { park.discard }.to change { ParkUser.count }.from(1).to(0)
      end

      it 'discards all associated payment records' do
        park_user
        payment

        expect { park.discard }.to change { Payment.active.count }.from(1).to(0)
      end
    end

    context 'when discarded_at is not present' do
      it 'does not fire' do
        expect(park).not_to receive(:cascade_discard)
        park.update(discarded_at: nil)
      end
    end

    context 'when discarded_at is present, but was also present in last save' do
      it 'does not fire' do
        park.discard

        expect(park).not_to receive(:cascade_discard)
        park.update(discarded_at: Time.now)
      end
    end
  end

  describe '#cascade_undiscard' do
    let(:park) { create :park }

    context 'when discarded_at is nil, but was present in last save' do
      before :each do
        @park_user = create(:park_user, park: park)
        @payment = create(:payment, park: park)

        park.discard
      end

      it 'fires' do
        expect(park).to receive(:cascade_undiscard)
        park.undiscard
      end

      it 'undiscards all associated payment records' do
        park.park_users
        park.payments

        expect { park.undiscard }.to change { Payment.active.count }.from(0).to(1)
      end
    end

    context 'when discarded_at is present' do
      it 'does not fire' do
        expect(park).not_to receive(:cascade_undiscard)
        park.update(discarded_at: Time.now)
      end
    end

    context 'when discarded_at is nil, but was also nil in last save' do
      it 'does not fire' do
        park.undiscard

        expect(park).not_to receive(:cascade_undiscard)
        park.update(discarded_at: nil)
      end
    end
  end

  describe '#full_address' do
    let(:big_addr) { create :park, address: 'addr1', city: 'city', postal_code: '12345' }
    let(:mid_addr) { create :park, address: 'addr2', postal_code: '12345' }
    let(:lil_addr) { create :park, address: 'addr3' }

    it 'concatentates the address' do
      expect(big_addr.full_address).to eq 'addr1, city, MI, 12345'
      expect(mid_addr.full_address).to eq 'addr2, 12345'
      expect(lil_addr.full_address).to eq 'addr3'
    end
  end

  describe '#good_address?' do
    let(:park) { create :park, address: 'address', city: 'city', state: 'state' }

    context 'when address is blank' do
      it 'retuns false' do
        park.update(address: nil)
        expect(park.good_address?).to eq false
      end
    end

    context 'when city is blank' do
      it 'retuns false' do
        park.update(city: '')
        expect(park.good_address?).to eq false
      end
    end

    context 'when state is blank' do
      it 'retuns false' do
        park.update(state: ' ')
        expect(park.good_address?).to eq false
      end
    end

    context 'when address, city and state are present' do
      it 'returns true' do
        expect(park.good_address?).to eq true
      end
    end
  end

  describe '#google_map' do
    let(:park) { create :park, address: '1600 Pennsylvania Ave NW', city: 'Washington', state: 'DC', postal_code: '20500' }

    context 'when not good_address?' do
      it 'returns no_property.jpg' do
        park.update(city: nil)
        expect(park.google_map).to eq 'no_property.jpg'
      end
    end

    context 'when good_address?' do
      it 'returns a url string' do
        expect(park.google_map[0..31]).to eq 'https://maps.googleapis.com/maps'
      end
    end
  end

  describe '#google_map_link' do
    let(:park) { create :park, address: '1600 Pennsylvania Ave NW', city: 'Washington', state: 'DC', postal_code: '20500' }

    context 'when not good_address?' do
      it 'returns false' do
        park.update(city: nil)
        expect(park.google_map_link).to eq false
      end
    end

    context 'when good_address?' do
      it 'returns a url string' do
        expect(park.google_map_link[0..30]).to eq 'https://www.google.com/maps/?q='
      end
    end
  end
end
