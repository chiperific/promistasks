# frozen_string_literal: true

class Payment < ApplicationRecord
  belongs_to :property, inverse_of: :payment, optional: true
  belongs_to :park,     inverse_of: :payment, optional: true
  belongs_to :utility,  inverse_of: :payment, optional: true
  belongs_to :contractor, class_name: 'User', inverse_of: :contractor_payments, optional: true
  belongs_to :client,     class_name: 'User', inverse_of: :client_payments, optional: true
  belongs_to :creator,    class_name: 'User', inverse_of: :created_payments

  monetize :bill_amt_cents
  monetize :payment_amt_cents, allow_nil: true, allow_blank: true
end
