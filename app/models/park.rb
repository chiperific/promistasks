# frozen_string_literal: true

class Park < ApplicationRecord
  has_many :properties, inverse_of: :park
  has_many :payments, inverse_of: :park, dependent: :destroy

  has_many :park_users, inverse_of: :park, dependent: :destroy
  has_many :users, through: :park_users
  accepts_nested_attributes_for :park_users, allow_destroy: true
end
