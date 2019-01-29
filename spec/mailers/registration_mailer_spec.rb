# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationMailer, type: :mailer do
  describe '#new_registration_notification' do
    let(:new_user) { create :user }
    let(:mail) { RegistrationMailer.with(user: new_user).new_registration_notification }

    context 'when Organization#volunteer_contact is set' do
      let(:volunteer_contact) { create :oauth_user }

      it 'emails the volunteer_contact' do
        Organization.first.update(volunteer_contact: volunteer_contact)

        perform_enqueued_jobs do
          mail.deliver_later
        end

        sent_mail = ActionMailer::Base.deliveries.last
        expect(sent_mail.to[0]).to eq volunteer_contact.email
      end
    end

    context 'when Organization#volunteer_contact is not set' do
      it 'emails the default_email' do
        perform_enqueued_jobs do
          mail.deliver_later
        end

        sent_mail = ActionMailer::Base.deliveries.last
        expect(sent_mail.to[0]).to eq Organization.first.default_email
      end
    end

    it 'gets enqueued' do
      expect { mail.deliver_later }.to have_enqueued_job.on_queue('mailers')
    end

    it 'sends an email' do
      expect {
        perform_enqueued_jobs do
          mail.deliver_later
        end
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end
end
