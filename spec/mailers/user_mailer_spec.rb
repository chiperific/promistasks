# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe '#payments_reminder' do
    before :each do
      @billing_contact = create(:oauth_user)
      Organization.first.update(billing_contact: @billing_contact)

      @user_related_by_prop = create(:oauth_user)
      @property = create(:property, creator: @user_related_by_prop)
      @user_related_by_task = create(:oauth_user)
      @task = create(:task, creator: @user_related_by_task)
      @unrelated_user = create(:oauth_user)
      @related_user = create(:oauth_user)

      @payment1 = create(:payment, creator: @related_user, due: Date.today + 12.days)
      @payment2 = create(:payment, property: @property, due: Date.today + 2.days)
      @payment3 = create(:payment, task: @task, due: Date.today + 2.days)
      @payment4 = create(:payment, due: Date.today - 3.days)
      @payment5 = create(:old_payment)
    end

    it 'sends an email' do
      UserMailer.payments_reminder(@billing_contact, true).deliver_now

      sent_mail = ActionMailer::Base.deliveries.last
      expect(sent_mail.subject).to eq '[PromiseTasks] Payment reminder'
    end

    context 'when user is' do
      context 'Organization#billing_contact' do
        it 'includes all upcoming and late payments' do
          mail = UserMailer.payments_reminder(@billing_contact, true).deliver_now

          expect(mail.body.encoded).to match(@payment1.to.name)
          expect(mail.body.encoded).to match(@payment2.to.name)
          expect(mail.body.encoded).to match(@payment3.to.name)
          expect(mail.body.encoded).to match(@payment4.to.name)
          expect(mail.body.encoded).not_to match(@payment5.to.name)
        end
      end

      context 'related by property' do
        it 'includes related upcoming and late payments' do
          mail = UserMailer.payments_reminder(@user_related_by_prop, false).deliver_now

          expect(mail.body.encoded).not_to match(@payment1.to.name)
          expect(mail.body.encoded).to match(@payment2.to.name)
          expect(mail.body.encoded).not_to match(@payment3.to.name)
          expect(mail.body.encoded).not_to match(@payment4.to.name)
          expect(mail.body.encoded).not_to match(@payment5.to.name)
        end
      end

      context 'related by task' do
        it 'includes related upcoming and late payments' do
          mail = UserMailer.payments_reminder(@user_related_by_task, false).deliver_now

          expect(mail.body.encoded).not_to match(@payment1.to.name)
          expect(mail.body.encoded).not_to match(@payment2.to.name)
          expect(mail.body.encoded).to match(@payment3.to.name)
          expect(mail.body.encoded).not_to match(@payment4.to.name)
          expect(mail.body.encoded).not_to match(@payment5.to.name)
        end
      end

      context 'totally unrelated to any payments' do
        it 'doesn\'t bother sending' do
          expect {
            UserMailer.payments_reminder(@unrelated_user, false).deliver_now
          }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end

      context 'directly related to a payment' do
        it 'includes related upcoming and late payments' do
          mail = UserMailer.payments_reminder(@related_user, false).deliver_now

          expect(mail.body.encoded).to match(@payment1.to.name)
          expect(mail.body.encoded).not_to match(@payment2.to.name)
          expect(mail.body.encoded).not_to match(@payment3.to.name)
          expect(mail.body.encoded).not_to match(@payment4.to.name)
          expect(mail.body.encoded).not_to match(@payment5.to.name)
        end
      end
    end
  end
end
