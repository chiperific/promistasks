# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentReminderJob, type: :job do
  describe '#perform' do
    context 'when there are payments that meet criteria' do
      pending 'calls UserMailer multiple times'
    end

    context 'when there are no payments that meet criteria' do
      pending 'doesn\'t call UserMailer at all'
    end
  end
end
