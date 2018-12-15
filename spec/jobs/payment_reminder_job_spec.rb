# frozen_string_literal: true

require 'rails_helper'
include ActiveJob::TestHelper

RSpec.describe PaymentReminderJob, type: :job do
  before :each do
    @admin = FactoryBot.create(:admin)
    @org = Organization.create
    @org.update(billing_contact: @admin)

    @property = FactoryBot.create(:property, creator: @admin)
  end

  describe '#perform' do
    context 'when there are payments that meet criteria' do
      before :each do
        3.times do
          FactoryBot.create(:payment, due: Date.today + 4.days, property: @property)
        end
      end

      it 'sends emails' do
        expect {
          PaymentReminderJob.new.perform
        }.to change { ActionMailer::Base.deliveries.size }.by(User.staff.count)
      end
    end

    context 'when there are no payments that meet criteria' do
      before :each do
        FactoryBot.create(:payment, due: Date.today + 18.days, property: @property) # too far in future
        FactoryBot.create(:payment, due: Date.today + 2.days, paid: Date.today) # already paid
        FactoryBot.create(:user, name: 'not related to any payments')

      end
      it 'doesn\'t send emails' do
        expect {
          PaymentReminderJob.new.perform
        }.not_to change { ActionMailer::Base.deliveries.size }
      end
    end
  end
end
