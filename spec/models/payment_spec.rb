# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'must be valid' do
    let(:payment)        { build :payment }
    let(:no_creator)     { build :payment, creator_id: nil }
    let(:no_bill_amt)    { build :payment, bill_amt_cents: nil }
    let(:no_paid_to)     { build :payment, paid_to: nil }
    let(:no_obo)         { build :payment, on_behalf_of: nil }

    context 'against the schema' do
      it 'in order to save' do
        expect(payment.save!(validate: false)).to eq true
        expect { no_creator.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_bill_amt.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_paid_to.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
        expect { no_obo.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      end
    end

    context 'against the model' do
      it 'in order to save' do
        expect(payment.save!).to eq true
        expect { no_creator.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_bill_amt.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_paid_to.save! }.to raise_error ActiveRecord::RecordInvalid
        expect { no_obo.save! }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe 'validates inclusions: ' do
    let(:good_method)     { build :payment, method: 'cash' }
    let(:bad_method)      { build :payment, method: 'monopoly money' }
    let(:good_obo)        { build :payment, on_behalf_of: 'property' }
    let(:bad_obo)         { build :payment, on_behalf_of: 'girlfriend' }
    let(:good_paid_to)    { build :payment, paid_to: 'utility' }
    let(:bad_paid_to)     { build :payment, paid_to: 'bookie' }
    let(:good_recurrence) { build :payment, recurrence: 'month' }
    let(:bad_recurrence)  { build :payment, recurrence: 'whenever' }
    let(:good_utility)    { build :payment, utility_type: 'gas' }
    let(:bad_utility)     { build :payment, utility_type: 'helium' }

    it '#method' do
      expect(good_method.save).to eq true

      expect(bad_method.valid?).to eq false
      expect(bad_method.errors[:method].present?).to eq true
    end

    it '#on_behalf_of' do
      expect(good_obo.save).to eq true

      expect(bad_obo.valid?).to eq false
      expect(bad_obo.errors[:on_behalf_of].present?).to eq true
    end

    it '#paid_to' do
      expect(good_paid_to.save).to eq true

      expect(bad_paid_to.valid?).to eq false
      expect(bad_paid_to.errors[:paid_to].present?).to eq true
    end

    it '#recurrence' do
      expect(good_recurrence.save).to eq true

      expect(bad_recurrence.valid?).to eq false
      expect(bad_recurrence.errors[:recurrence].present?).to eq true
    end

    it '#utility_type' do
      expect(good_utility.save).to eq true

      expect(bad_utility.valid?).to eq false
      expect(bad_utility.errors[:utility_type].present?).to eq true
    end
  end

  describe 'limits records by scope' do
    let(:future_15) { create :payment } # due: Date.today + 15.days
    let(:future_9)  { create :payment, due: Date.today + 9.days }
    let(:future_4)  { create :payment, due: Date.today + 4.days }
    let(:today)     { create :payment, due: Date.today }
    let(:past)      { create :payment, due: Date.today - 1.day }
    let(:paid)      { create :payment, due: Date.today + 1.day, paid: Date.today }
    let(:past_paid) { create :payment, due: Date.today - 4.days, paid: Date.today - 4.days }
    let(:inactive)  { create :payment, discarded_at: Date.today }

    context '#due_in_future' do
      it 'returns payments where due >= Date.today' do
        expect(Payment.due_in_future).to include future_15
        expect(Payment.due_in_future).to include future_9
        expect(Payment.due_in_future).to include future_4
        expect(Payment.due_in_future).to include today
        expect(Payment.due_in_future).to include paid
        expect(Payment.due_in_future).not_to include past
        expect(Payment.due_in_future).not_to include past_paid
        expect(Payment.due_in_future).not_to include inactive
      end
    end

    context '#due_in_past' do
      it 'returns active payments where due < Date.today' do
        expect(Payment.due_in_past).not_to include future_15
        expect(Payment.due_in_past).not_to include future_9
        expect(Payment.due_in_past).not_to include future_4
        expect(Payment.due_in_past).not_to include today
        expect(Payment.due_in_past).not_to include paid
        expect(Payment.due_in_past).to include past
        expect(Payment.due_in_past).to include past_paid
        expect(Payment.due_in_past).not_to include inactive
      end
    end

    context '#paid' do
      it 'returns active payments where paid != nil' do
        expect(Payment.paid).not_to include future_15
        expect(Payment.paid).not_to include future_9
        expect(Payment.paid).not_to include future_4
        expect(Payment.paid).not_to include today
        expect(Payment.paid).to include paid
        expect(Payment.paid).to include past_paid
        expect(Payment.paid).not_to include inactive
      end
    end

    context '#not_paid' do
      it 'returns active payments where paid == nil' do
        expect(Payment.not_paid).to include future_15
        expect(Payment.not_paid).to include future_9
        expect(Payment.not_paid).to include future_4
        expect(Payment.not_paid).to include today
        expect(Payment.not_paid).to include past
        expect(Payment.not_paid).not_to include paid
        expect(Payment.not_paid).not_to include past_paid
        expect(Payment.not_paid).not_to include inactive
      end
    end

    context '#due_within' do
      it 'returns active payments where paid == nil and the due date is within X days' do
        expect(Payment.due_within(7)).not_to include future_15
        expect(Payment.due_within(17)).to include future_15
        expect(Payment.due_within(7)).not_to include future_9
        expect(Payment.due_within(17)).to include future_9
        expect(Payment.due_within(3)).not_to include future_4
        expect(Payment.due_within(7)).to include future_4
        expect(Payment.due_within(7)).to include today
        expect(Payment.due_within(17)).to include today
        expect(Payment.due_within(7)).not_to include paid
        expect(Payment.due_within(17)).not_to include paid
        expect(Payment.due_within(20)).not_to include inactive
      end
    end

    context '#past_due' do
      it 'returns active payments where paid == nil && due < Date.today' do
        expect(Payment.past_due).not_to include future_15
        expect(Payment.past_due).not_to include future_9
        expect(Payment.past_due).not_to include future_4
        expect(Payment.past_due).not_to include today
        expect(Payment.past_due).to include past
        expect(Payment.past_due).not_to include past_paid
        expect(Payment.past_due).not_to include inactive
      end
    end

    describe 'relation scopes' do
      let(:user)       { create :user }
      let(:prop1)      { create :property, creator: user }
      let(:task1)      { create :task, owner: user }
      let(:paym_task1) { create :payment, task: task1 }
      let(:prop2)      { create :property }
      let(:task2)      { create :task, property: prop2, owner: user }
      let(:paym_prop1) { create :payment, property: prop1 }
      let(:paym_prop2) { create :payment, property: prop2 }

      context '#related_by_property_to' do
        it 'returns active payments with an associated property that is related to a given User' do
          prop2
          task2
          paym_prop2

          expect(Payment.related_by_property_to(user)).to include paym_prop1
          expect(Payment.related_by_property_to(user)).to include paym_prop2
        end
      end

      context '#related_by_task_to' do
        it 'returns active payments with an associated task that is related to a given User' do
          task1

          expect(Payment.related_by_task_to(user)).to include paym_task1
        end
      end

      context '#related_to' do
        it 'returns active payments with an associated property or task that are related to a given User' do
          task1
          task2
          prop2
          paym_prop2

          expect(Payment.related_to(user)).to include paym_prop1
          expect(Payment.related_to(user)).to include paym_prop2
          expect(Payment.related_to(user)).to include paym_task1
        end
      end
    end
  end

  describe 'requires booleans to be in a state:' do
    let(:nil_recurring)              { build :payment, recurring: nil }
    let(:nil_send_email_reminders)   { build :payment, send_email_reminders: nil }
    let(:nil_suppress_system_alerts) { build :payment, suppress_system_alerts: nil }

    it '#recurring' do
      expect { nil_recurring.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect(nil_recurring.valid?).to eq false
      expect(nil_recurring.errors[:recurring].present?).to eq true
    end

    it '#send_email_reminders' do
      expect { nil_send_email_reminders.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect(nil_send_email_reminders.valid?).to eq false
      expect(nil_send_email_reminders.errors[:send_email_reminders].present?).to eq true
    end

    it '#suppress_system_alerts' do
      expect { nil_suppress_system_alerts.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect(nil_suppress_system_alerts.valid?).to eq false
      expect(nil_suppress_system_alerts.errors[:suppress_system_alerts].present?).to eq true
    end
  end

  describe '#for' do
    let(:good_for)  { build :payment }
    let(:bad_for)   { build :payment, on_behalf_of: 'beer money' }
    let(:blank_for) { build :payment, on_behalf_of: nil }

    context 'when on_behalf_of is present' do
      it 'calls public_send on the text of on_behalf_of' do
        expect(good_for.for).to eq good_for.property
      end
    end

    context 'when on_behalf_of is blank' do
      it 'returns nil' do
        expect(blank_for.for).to eq nil
      end
    end

    context 'when on_behalf_of is a bad value' do
      it 'returns nil' do
        expect(bad_for.for).to eq nil
      end
    end
  end

  describe '#from' do
    let(:pay_org)  { build :payment_org }
    let(:pay_util) { build :payment }
    let(:pay_park) { build :payment_park }

    context 'when paid_to != organization' do
      it 'returns the Organization' do
        expect(pay_util.from).to eq Organization.first
        expect(pay_park.from).to eq Organization.first
      end
    end

    context 'when paid_to == organization' do
      it 'returns a model object' do
        expect(pay_org.from.is_a?(Utility)).to eq true
      end
    end
  end

  describe '#manage_relationships' do
    before :each do
      @payment = build(:payment)
      @task = create(:task)
      @payment_params = ActionController::Parameters.new({ send_email_reminders: '0', paid_to: 'utility', on_behalf_of: 'property', contractor_id: '', park_id: '', utility_id: '1', client_id: '', property_id: '1', client_id_obo: '', task_id: @task.id.to_s, notes: '', bill_amt: '400.00', payment_amt: '', method: '', received: 'Nov 25, 2018', due: 'Dec 10, 2018', paid: '', utility_type: 'water', utility_account: '', utility_service_started: '', recurring: '0', recurrence: '' })
    end

    it 'calls #remove_relationships' do
      expect(@payment).to receive(:remove_relationships)

      @payment.manage_relationships(@payment_params)
    end

    it 'sets a relationship based upon payment_params[:paid_to]' do
      @payment.send(:remove_relationships)

      expect(@payment.paid_to).to eq 'utility'
      expect(@payment.utility_id).to eq nil

      @payment.manage_relationships(@payment_params)

      expect(@payment.utility_id).not_to eq nil
    end

    it 'sets a relationship based upon payment_params[:on_behalf_of]' do
      @payment.send(:remove_relationships)

      expect(@payment.on_behalf_of).to eq 'property'
      expect(@payment.property_id).to eq nil

      @payment.manage_relationships(@payment_params)

      expect(@payment.property_id).not_to eq nil
    end

    it 'sets a task_id based upon payment_params[:task_id]' do
      expect(@payment.task_id).to eq nil

      @payment.manage_relationships(@payment_params)

      expect(@payment.task_id).to eq @task.id
    end
  end

  describe '#past_due?' do
    let(:no_due)     { build :payment, due: nil }
    let(:past_due)   { build :payment, due: Date.today - 3.days }
    let(:future_due) { build :payment }

    it 'returns false unless due is present' do
      expect(no_due.past_due?).to eq false
    end
    it 'returns true if due is in the past' do
      expect(past_due.past_due?).to eq true
    end
    it 'returns false if due is in the future' do
      expect(future_due.past_due?).to eq false
    end
  end

  describe '#reason' do
    let(:pmt_util) { build :payment }
    let(:task) { create :task }
    let(:pmt_task) { create :payment, utility_type: nil, task: task }
    let(:pmt_util_task) { create :payment, task: task }
    let(:pmt_unkn) { create :payment, utility_type: nil }

    it 'returns utility_type if present' do
      task

      expect(pmt_util.reason).to eq pmt_util.utility_type
      expect(pmt_util_task.reason).to eq pmt_util_task.utility_type
    end

    it 'returns task.title if present and utility_type is not present' do
      task

      expect(pmt_task.reason).to eq pmt_task.task.title
      expect(pmt_util_task.reason).not_to eq pmt_util_task.task.title
    end

    it 'returns "Unknown" if utility_type and task are not present' do
      expect(pmt_unkn.reason).to eq 'Unknown'
    end
  end

  describe '#status' do
    let(:paid_present) { build :payment, paid: Date.today }
    let(:due_future) { build :payment }
    let(:due_past) { build :payment, due: Date.today - 10.days }
    let(:received) { build :payment, due: nil }
    let(:no_dates) { build :payment, received: nil, due: nil }

    it 'returns Paid on... if paid is present' do
      expect(paid_present.status).to start_with 'Paid on'
    end
    it 'returns Due on... if due is in the future and paid is not present' do
      expect(due_future.status).to start_with 'Due on'
    end
    it 'returns PAST DUE as of... if due is in the past and paid is not present' do
      expect(due_past.status).to start_with 'PAST DUE as of'
    end
    it 'returns Received on... if received is present, and due and paid are missing' do
      expect(received.status).to start_with 'Received on'
    end
    it 'returns No dates set if paid is not present, due is not present and received is not present' do
      expect(no_dates.status).to eq 'No dates set'
    end
  end

  describe '#to' do
    let(:org) { build :payment_org }
    let(:not_org) { build :payment }
    let(:nil_val) { build :payment, paid_to: nil }
    let(:bad_val) { build :payment, paid_to: 'beer place' }

    describe 'when paid_to == organization' do
      it 'returns the organization' do
        expect(org.to).to eq Organization.first
      end
    end

    describe 'when paid_to != organization' do
      it 'attempts to call public_send on the text of paid_to' do
        expect(not_org.to).to eq not_org.utility
      end
    end

    describe 'when paid_to is nil' do
      it 'returns nil' do
        expect(nil_val.to).to eq nil
      end
    end

    describe 'when paid_to is a bad value' do
      it 'returns nil' do
        expect(bad_val.to).to eq nil
      end
    end
  end

  # private methods

  describe '#create_next_instance' do
    let(:no_recurrence)     { build :payment, recurring: true, paid: Date.today }
    let(:no_recurring)      { build :payment, paid: Date.today, recurrence: @sched }
    let(:no_paid)           { build :payment, recurring: true, recurrence: @sched }
    let(:previously_paid)   { create :payment, paid: Date.yesterday }
    let(:recurring_payment) { build :payment, recurrence: 'month', recurring: true, paid: Date.today }

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
    let(:property_association) { build :payment }
    let(:park_association) { build :payment }
    let(:utility_association) { build :payment }
    let(:contractor_association) { build :payment_contractor }
    let(:client_association) { build :payment_client }
    let(:no_associations) { build :payment, utility_id: nil, property_id: nil }

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

      it 'adds an error to #paid_to and #on_behalf_of' do
        expect(no_associations.valid?).to eq false
        expect(no_associations.errors[:paid_to].present?).to eq true
        expect(no_associations.errors[:on_behalf_of].present?).to eq true
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
      let(:has_recurrence) { build :payment, recurrence: 'month' }

      it 'returns a date that represents the next due date' do
        expect(has_recurrence.send(:next_recurrence).is_a?(Date)).to eq true
      end
    end
  end

  describe '#remove_relationships' do
    let(:payment) { build :payment }

    it 'removes all relationships' do
      expect(payment.utility_id.present?).to eq true
      expect(payment.property_id.present?).to eq true

      payment.send(:remove_relationships)

      expect(payment.utility_id.present?).to eq false
      expect(payment.property_id.present?).to eq false
    end
  end
end
