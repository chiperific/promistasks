# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe '#url_for_sync' do
    before :each do
      helper.request.env['REQUEST_URI'] = 'http://localhost:3000/users/1/api_sync'
    end

    context 'when request.env has HTTP_REFERER' do
      it 'appends ?syncing=true to HTTP_REFERER' do
        helper.request.env['HTTP_REFERER'] = 'http://localhost:3000/tasks'
        expect(helper.url_for_sync).to eq 'http://localhost:3000/tasks?syncing=true'
      end
    end

    context 'when request.env has no HTTP_REFERER' do
      it 'appends ?syncing=true to properties_path' do
        expect(helper.url_for_sync).to eq '/properties?syncing=true'
      end
    end
  end

  describe 'alert helpers' do
    describe '#pulse_alert' do
      it 'returns true if there are past_due tasks' do
        tasks      = double(:task, past_due: [1, 1, 1, 1])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [])

        expect(helper.pulse_alert(tasks, properties, payments)).to eq true
      end

      it 'returns true if there are properties over budget' do
        tasks      = double(:task, past_due: [])
        properties = double(:property, over_budget: [1, 2, 3, 4], nearing_budget: [])
        payments   = double(:payment, past_due: [])

        expect(helper.pulse_alert(tasks, properties, payments)).to eq true
      end

      it 'returns true if there are past_due payments' do
        tasks      = double(:task, past_due: [])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [1, 2, 3])

        expect(helper.pulse_alert(tasks, properties, payments)).to eq true
      end

      it 'returns false if no conditions are met' do
        tasks      = double(:task, past_due: [])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [])

        expect(helper.pulse_alert(tasks, properties, payments)).to eq false
      end
    end

    describe '#amber' do
      it 'returns true if there are tasks due within 7 days' do
        tasks      = double(:task, past_due: [])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [])
        allow(tasks).to receive(:due_within).with(7).and_return([1, 2])
        allow(payments).to receive(:due_within).with(7).and_return([])

        expect(helper.amber(tasks, properties, payments)).to eq true
      end

      it 'returns true if there are payments due within 7 days' do
        tasks      = double(:task, past_due: [])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [])
        allow(tasks).to receive(:due_within).with(7).and_return([])
        allow(payments).to receive(:due_within).with(7).and_return([1, 2])

        expect(helper.amber(tasks, properties, payments)).to eq true
      end

      it 'returns false if no conditions are met' do
        tasks      = double(:task, past_due: [])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [])
        allow(tasks).to receive(:due_within).with(7).and_return([])
        allow(payments).to receive(:due_within).with(7).and_return([])

        expect(helper.amber(tasks, properties, payments)).to eq false
      end
    end

    describe '#orange' do
      it 'returns true if there are properties nearing budget' do
        tasks      = double(:task, past_due: [])
        properties = double(:property, over_budget: [], nearing_budget: [1, 2, 3])
        payments   = double(:payment, past_due: [])
        allow(tasks).to receive(:due_within).with(14).and_return([])
        allow(payments).to receive(:due_within).with(14).and_return([])

        expect(helper.orange(tasks, properties, payments)).to eq true
      end

      it 'returns true if there are tasks due within 14 days' do
        tasks      = double(:task, past_due: [])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [])
        allow(tasks).to receive(:due_within).with(14).and_return([1, 2, 3])
        allow(payments).to receive(:due_within).with(14).and_return([])

        expect(helper.orange(tasks, properties, payments)).to eq true
      end

      it 'returns true if there are payments due within 14 days' do
        tasks      = double(:task, past_due: [])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [])
        allow(tasks).to receive(:due_within).with(14).and_return([])
        allow(payments).to receive(:due_within).with(14).and_return([1, 2, 3])

        expect(helper.orange(tasks, properties, payments)).to eq true
      end

      it 'returns false if no conditions are met' do
        tasks      = double(:task, past_due: [])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [])
        allow(tasks).to receive(:due_within).with(14).and_return([])
        allow(payments).to receive(:due_within).with(14).and_return([])

        expect(helper.orange(tasks, properties, payments)).to eq false
      end
    end

    describe '#green' do
      it 'returns true if there are tasks created since the user last signed in' do
        tasks      = double(:task, needs_more_info: [], created_since: [1, 2, 3])
        properties = double(:property)
        payments   = double(:payment)
        user       = double(:user, last_sign_in_at: Time.now)

        expect(helper.green(tasks, properties, payments, user)).to eq true
      end

      it 'returns true if there are tasks that need more information' do
        tasks      = double(:task, needs_more_info: [1, 2, 3], created_since: [])
        properties = double(:property)
        payments   = double(:payment)
        user       = double(:user, last_sign_in_at: Time.now)

        expect(helper.green(tasks, properties, payments, user)).to eq true
      end

      it 'returns false if no conditions are met' do
        tasks      = double(:task, needs_more_info: [], created_since: [])
        properties = double(:property)
        payments   = double(:payment)
        user       = double(:user, last_sign_in_at: Time.now)

        expect(helper.green(tasks, properties, payments, user)).to eq false
      end
    end

    describe '#show_alert' do
      it 'returns true if pulse_alert is true' do
        tasks = double(:task, past_due: [1, 2, 3])
        properties = double(:property, over_budget: [])
        payments   = double(:payment, past_due: [])
        user = double(:user, last_sign_in_at: Time.now)

        expect(helper.show_alert(tasks, properties, payments, user)).to eq true
      end

      it 'returns true if amber is true' do
        tasks      = double(:task, past_due: [])
        properties = double(:property, over_budget: [])
        payments   = double(:payment, past_due: [])
        user       = double(:user, last_sign_in_at: Time.now)
        allow(tasks).to receive(:due_within).with(7).and_return([1, 2])

        expect(helper.show_alert(tasks, properties, payments, user)).to eq true
      end

      it 'returns true if orange is true' do
        tasks      = double(:task, past_due: [], due_within: [])
        properties = double(:property, over_budget: [], nearing_budget: [1, 2, 3])
        payments   = double(:payment, past_due: [], due_within: [])
        user       = double(:user, last_sign_in_at: Time.now)

        expect(helper.show_alert(tasks, properties, payments, user)).to eq true
      end

      it 'returns true if green is true' do
        tasks      = double(:task, past_due: [], due_within: [], created_since: [1, 2])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [], due_within: [])
        user       = double(:user, last_sign_in_at: Time.now)

        expect(helper.show_alert(tasks, properties, payments, user)).to eq true
      end
    end

    describe '#alert_color' do
      it 'returns red if pulse_alert is true' do
        tasks      = double(:task, past_due: [1, 2, 3], due_within: [], created_since: [])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [], due_within: [])

        expect(helper.alert_color(tasks, properties, payments)).to eq 'red'
      end

      it 'returns amber if there are tasks due within 7 days and pulse_alert is false' do
        tasks      = double(:task, past_due: [], due_within: [1, 2, 3], created_since: [])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [], due_within: [])

        expect(helper.alert_color(tasks, properties, payments)).to eq 'amber'
      end

      it 'returns orange if there are tasks that need more information but not due within 7 days and pulse_alert is false' do
        tasks      = double(:task, past_due: [], due_within: [], created_since: [])
        properties = double(:property, over_budget: [], nearing_budget: [1, 2, 3])
        payments   = double(:payment, past_due: [], due_within: [])

        expect(helper.alert_color(tasks, properties, payments)).to eq 'orange'
      end

      it 'returns green if no tasks need more info or are due within 7 days and pulse_alert is false' do
        tasks      = double(:task, past_due: [], due_within: [], created_since: [])
        properties = double(:property, over_budget: [], nearing_budget: [])
        payments   = double(:payment, past_due: [], due_within: [])

        expect(helper.alert_color(tasks, properties, payments)).to eq 'green'
      end
    end
  end
end
