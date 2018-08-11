# frozen_string_literal: true

class Utility < ApplicationRecord
  has_many :payments, inverse_of: :utility, dependent: :destroy
  has_many :properties, through: :payments
  has_many :parks, through: :payments
end
