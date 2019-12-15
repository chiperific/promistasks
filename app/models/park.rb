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

  after_validation :geocode, if: -> { address_has_changed? || latitude.blank? || longitude.blank? }
  after_save :cascade_discard, if: -> { discarded_at.present? && discarded_at_before_last_save.nil? }
  after_save :cascade_undiscard, if: -> { discarded_at.nil? && discarded_at_before_last_save.present? }

  scope :created_since, ->(time) { where('created_at >= ?', time) }

  class << self
    alias archived discarded
    alias active kept
  end

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
    return 'no_property.jpg' if !good_address? || latitude.blank? || longitude.blank?

    center = [latitude, longitude].join(',')
    key = Rails.application.credentials.google_api_key

    secret = Rails.application.credentials.google_maps_secret
    url = "https://maps.googleapis.com/maps/api/staticmap?key=#{key}&size=355x266&zoom=17&markers=color:red%7C#{center}"

    GoogleUrlSigner.sign(url, secret)
  end

  def google_map_link
    return false unless good_address?

    base = 'https://www.google.com/maps/?q='
    base + full_address.tr(' ', '+')
  end

  def staff_contact
    park_users.where(relationship: 'staff contact').last&.user
  end
end
