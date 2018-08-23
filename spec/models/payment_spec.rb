# frozen_string_literal: true

require 'rails_helper'
include IceCube

RSpec.describe Payment, type: :model do
  before :each do
    @sched = Schedule.new
    @sched.add_recurrence_rule(Rule.monthly.day_of_month(15))
  end

  describe 'must be valid' do
    let(:payment)     { build :payment }
    let(:no_creator)  { build :payment, creator_id: nil }
    let(:no_bill_amt) { build :payment, bill_amt_cents: nil }
    let(:bad_utility) { build :payment, utility_type: 'helium' }
    let(:bad_method)  { build :payment, method: 'monopoly money' }

    context 'against the schema' do
      it 'in order to save' do
        expect(payment.save!(validate: false)).to eq true
        expect { no_creator.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_bill_amt.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      end
    end

    context 'against the model' do
      it 'in order to save' do
        expect(payment.save!).to eq true
        expect { no_creator.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_bill_amt.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { bad_utility.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { bad_method.save! }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe 'validates inclusions: ' do
    let(:good_utility) { build :payment, utility_type: 'gas' }
    let(:good_method)  { build :payment, method: 'cash' }
    let(:bad_utility)  { build :payment, utility_type: 'helium' }
    let(:bad_method)   { build :payment, method: 'monopoly money' }

    it '#utility_type' do
      expect(good_utility.save).to eq true

      expect(bad_utility.valid?).to eq false
      expect(bad_utility.errors[:utility_type].present?).to eq true
    end

    it '#method' do
      expect(good_method.save).to eq true

      expect(bad_method.valid?).to eq false
      expect(bad_method.errors[:method].present?).to eq true
    end
  end

  describe 'requires booleans to be in a state:' do
    let(:nil_recurring)              { build :payment, recurring: nil }
    let(:nil_send_email_reminders)   { build :payment, send_email_reminders: nil }
    let(:nil_suppress_system_alerts) { build :payment, suppress_system_alerts: nil }

    it '#recurring' do
      expect(nil_recurring.valid?).to eq false
      expect(nil_recurring.errors[:recurring].present?).to eq true
    end

    it '#send_email_reminders' do
      expect(nil_send_email_reminders.valid?).to eq false
      expect(nil_send_email_reminders.errors[:send_email_reminders].present?).to eq true
    end

    it '#suppress_system_alerts' do
      expect(nil_suppress_system_alerts.valid?).to eq false
      expect(nil_suppress_system_alerts.errors[:suppress_system_alerts].present?).to eq true
    end
  end

  describe '#create_next_instance' do
    let(:no_recurrence)     { build :payment, recurring: true, paid: Date.today }
    let(:no_recurring)      { build :payment, paid: Date.today, recurrence: @sched }
    let(:no_paid)           { build :payment, recurring: true, recurrence: @sched }
    let(:previously_paid)   { create :payment, paid: Date.yesterday }
    let(:recurring_payment) { build :payment, recurrence: @sched, recurring: true, paid: Date.today }

    context 'when recurrence is not present' do
      it 'doesn\'t fire' do
        expect(no_recurrence).not_to receive(:create_next_instance)
        no_recurrence.save
      end
    end

    context 'when recurring is not present' do
      it 'doesn\'t fire' do
        expect(no_recurring).not_to receive(:create_next_instance)
        no_recurring.save
      end
    end

    context 'when paid is not present' do
      it 'doesn\'t fire' do
        expect(no_paid).not_to receive(:create_next_instance)
        no_paid.save
      end
    end

    context 'when paid is present, and paid was present before last save' do
      it 'doesn\'t fire' do
        expect(previously_paid).not_to receive(:create_next_instance)
        previously_paid.save
      end
    end

    context 'when recurrence, recurring, and paid are present and paid was blank before last save' do
      it 'fires' do
        expect(recurring_payment).to receive(:create_next_instance)
        recurring_payment.save
      end

      it 'creates another payment object' do
        expect { recurring_payment.save }.to change { Payment.count }.by(2)
      end
    end
  end

  describe '#must_have_association' do
    let(:property_association) { build :payment_property }
    let(:park_association) { build :payment }
    let(:utility_association) { build :payment_utility }
    let(:task_association) { build :payment_task }
    let(:contractor_association) { build :payment_contractor }
    let(:client_association) { build :payment_client }
    let(:no_associations) { build :payment, park_id: nil }

    context 'when property is associated' do
      it 'returns true' do
        expect(property_association.send(:must_have_association)).to eq true
      end
    end

    context 'when park is associated' do
      it 'returns true' do
        expect(park_association.send(:must_have_association)).to eq true
      end
    end

    context 'when utility is associated' do
      it 'returns true' do
        expect(utility_association.send(:must_have_association)).to eq true
      end
    end

    context 'when task is associated' do
      it 'returns true' do
        expect(task_association.send(:must_have_association)).to eq true
      end
    end

    context 'when contractor is associated' do
      it 'returns true' do
        expect(contractor_association.send(:must_have_association)).to eq true
      end
    end

    context 'when client is associated' do
      it 'returns true' do
        expect(client_association.send(:must_have_association)).to eq true
      end
    end

    context 'when nothing is associated' do
      it 'returns false' do
        expect(no_associations.send(:must_have_association)).to eq false
      end

      it 'adds an error to bill_amt' do
        expect(no_associations.valid?).to eq false
        expect(no_associations.errors[:bill_amt].present?).to eq true
      end
    end
  end

  describe '#next_recurrence' do
    context 'when recurrence is not present' do
      let(:no_recurrence) { build :payment }

      it 'returns nil' do
        expect(no_recurrence.send(:next_recurrence)).to eq nil
      end
    end

    context 'when recurrence is present' do
      let(:has_recurrence) { build :payment, recurrence: @sched }

      it 'returns a date that represents the next due date' do
        expect(has_recurrence.send(:next_recurrence).is_a?(Date)).to eq true
      end
    end
  end
end
