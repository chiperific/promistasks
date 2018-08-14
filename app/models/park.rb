# frozen_string_literal: true

class Park < ApplicationRecord
  include Discard::Model

  has_many :properties, inverse_of: :park
  has_many :payments, inverse_of: :park, dependent: :destroy

  has_many :park_users, inverse_of: :park, dependent: :destroy
  has_many :users, through: :park_users
  accepts_nested_attributes_for :park_users, allow_destroy: true

  has_many :payments, inverse_of: :park, dependent: :destroy
  accepts_nested_attributes_for :payments, allow_destroy: true

  validates :name, presence: true, uniqueness: true

  geocoded_by :full_address

  after_validation :geocode, if: -> { address_has_changed? }
  after_save :cascade_discard, if: -> { discarded_at.present? && discarded_at_before_last_save.nil? }
  after_save :cascade_undiscard, if: -> { discarded_at.nil? && discarded_at_before_last_save.present? }

  def address_has_changed?
    return false if address.blank?
    address_changed? ||
      city_changed? ||
      state_changed? ||
      postal_code_changed?
  end

  def cascade_discard
    park_users.destroy_all
    payments.each(&:discard)
  end

  def cascade_undiscard
    payments.each(&:undiscard)
  end

  def full_address
    addr = address
    addr += ', ' + city unless city.blank?
    addr += ', ' + state unless city.blank?
    addr += ', ' + postal_code unless postal_code.blank?
    addr
  end

  def good_address?
    address.present? && city.present? && state.present?
  end

  def google_map
    return 'no_property.jpg' unless good_address?
    center = [latitude, longitude].join(',')
    key = Rails.application.secrets.google_maps_api_key
    "https://maps.googleapis.com/maps/api/staticmap?key=#{key}&size=355x266&zoom=17&markers=color:red%7C#{center}"
  end

  def google_map_link
    return false unless good_address?
    base = 'https://www.google.com/maps/?q='
    base + full_address.tr(' ', '+')
  end
end
