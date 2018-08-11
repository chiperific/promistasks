# frozen_string_literal: true

class ParkUser < ApplicationRecord
  belongs_to :park, inverse_of: :park_users
  belongs_to :user, inverse_of: :park_users

  validates_presence_of :park, :user
end
