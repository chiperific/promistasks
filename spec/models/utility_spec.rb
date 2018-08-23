# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Utility, type: :model do
  describe 'must be valid' do
    let(:utility)  { build :utility }
    let(:no_name)  { build :utility, name: nil }
    let(:dup_name) { build :utility }

    context 'against the schema' do
      it 'in order to save' do
        expect(utility.save(validate: false)).to eq true
        expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation

        dup_name.name = utility.name
        expect { dup_name.save!(validate: false) }.to raise_error ActiveRecord::RecordNotUnique
      end
    end

    context 'against the model' do
      it 'in order to save' do
        expect(utility.save).to eq true
        expect { no_name.save! }.to raise_error ActiveRecord::RecordInvalid

        dup_name.name = utility.name
        expect { dup_name.save! }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#address_has_changed?' do
    let(:utility) { build :utility, address: 'addr1', city: 'city', postal_code: '12345' }

    it 'returns true if address_changed?' do
      utility.address = 'new address'

      expect(utility.address_changed?).to eq true
      expect(utility.address_has_changed?).to eq true
    end

    it 'returns true if city_changed?' do
      utility.city = 'new address'

      expect(utility.city_changed?).to eq true
      expect(utility.address_has_changed?).to eq true
    end

    it 'returns true if state_changed?' do
      utility.state = 'new state'

      expect(utility.state_changed?).to eq true
      expect(utility.address_has_changed?).to eq true
    end

    it 'returns true if postal_code_changed?' do
      utility.postal_code = '12345'

      expect(utility.postal_code_changed?).to eq true
      expect(utility.address_has_changed?).to eq true
    end

    it 'returns false if no address fields have changed' do
      utility.save
      utility.name = 'new name'

      expect(utility.address_has_changed?).to eq false
    end
  end

  describe '#full_address' do
    let(:big_addr) { create :utility, address: 'addr1', city: 'city', postal_code: '12345' }
    let(:mid_addr) { create :utility, address: 'addr2', postal_code: '12345' }
    let(:lil_addr) { create :utility, address: 'addr3' }

    it 'concatentates the address' do
      expect(big_addr.full_address).to eq 'addr1, city, MI, 12345'
      expect(mid_addr.full_address).to eq 'addr2, 12345'
      expect(lil_addr.full_address).to eq 'addr3'
    end
  end

  describe '#good_address?' do
    let(:utility) { create :utility, address: 'address', city: 'city', state: 'state' }

    context 'when address is blank' do
      it 'retuns false' do
        utility.update(address: nil)
        expect(utility.good_address?).to eq false
      end
    end

    context 'when city is blank' do
      it 'retuns false' do
        utility.update(city: '')
        expect(utility.good_address?).to eq false
      end
    end

    context 'when state is blank' do
      it 'retuns false' do
        utility.update(state: ' ')
        expect(utility.good_address?).to eq false
      end
    end

    context 'when address, city and state are present' do
      it 'returns true' do
        expect(utility.good_address?).to eq true
      end
    end
  end

  describe '#google_map' do
    let(:utility) { create :utility, address: '1600 Pennsylvania Ave NW', city: 'Washington', state: 'DC', postal_code: '20500' }

    context 'when not good_address?' do
      it 'returns no_property.jpg' do
        utility.update(city: nil)
        expect(utility.google_map).to eq 'no_property.jpg'
      end
    end

    context 'when good_address?' do
      it 'returns a url string' do
        expect(utility.google_map[0..31]).to eq 'https://maps.googleapis.com/maps'
      end
    end
  end

  describe '#google_map_link' do
    let(:utility) { create :utility, address: '1600 Pennsylvania Ave NW', city: 'Washington', state: 'DC', postal_code: '20500' }

    context 'when not good_address?' do
      it 'returns false' do
        utility.update(city: nil)
        expect(utility.google_map_link).to eq false
      end
    end

    context 'when good_address?' do
      it 'returns a url string' do
        expect(utility.google_map_link[0..30]).to eq 'https://www.google.com/maps/?q='
      end
    end
  end

  # start private methods

  describe '#discard_payments' do
    let(:active_utility)    { build :utility, discarded_at: nil }
    let(:discarded_utility) { build :utility, discarded_at: Time.now }

    context 'when discarded_at is blank' do
      it 'doesn\'t fire' do
        expect(active_utility).not_to receive(:discard_payments)
        active_utility.save
      end
    end

    context 'when discarded_at is present but was present before last save' do
      it 'doesn\'t fire' do
        discarded_utility.save

        expect(discarded_utility).not_to receive(:discard_payments)
        discarded_utility.update(discarded_at: Time.now + 3.minutes)
      end
    end

    context 'when discarded_at is present and was blank before last save' do
      it 'fires' do
        expect(discarded_utility).to receive(:discard_payments)

        discarded_utility.save
      end

      it 'discards all child payments' do
        active_utility.save
        3.times do
          create(:payment, utility: active_utility)
        end

        expect(active_utility.payments.active.count).to eq 3

        active_utility.discard

        expect(active_utility.payments.active.count).to eq 0
        expect(active_utility.payments.count).to eq 3
      end
    end
  end

  describe '#undiscard_payments' do
    let(:active_utility)    { build :utility, discarded_at: nil }
    let(:discarded_utility) { build :utility, discarded_at: Time.now }

    context 'when discarded_at is present' do
      it 'doesn\'t fire' do
        expect(discarded_utility).not_to receive(:undiscard_payments)
        discarded_utility.save
      end
    end

    context 'when discarded_at is blank but was blank before last save' do
      it 'doesn\'t fire' do
        active_utility.save

        expect(active_utility).not_to receive(:undiscard_payments)
        active_utility.update(name: 'new name')
      end
    end

    context 'when discarded_at is blank and was present before last save' do
      it 'fires' do
        discarded_utility.save
        expect(discarded_utility).to receive(:undiscard_payments)

        discarded_utility.undiscard
      end

      it 'undiscards all child payments' do
        discarded_utility.save
        3.times do
          create(:payment, utility: discarded_utility, discarded_at: Time.now)
        end

        expect(discarded_utility.payments.discarded.count).to eq 3

        discarded_utility.undiscard

        expect(discarded_utility.payments.discarded.count).to eq 0
        expect(discarded_utility.payments.count).to eq 3
      end
    end
  end
end
