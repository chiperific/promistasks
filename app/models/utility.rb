# frozen_string_literal: true

class Utility < ApplicationRecord
  include Discard::Model

  has_many :payments, inverse_of: :utility, dependent: :destroy
  accepts_nested_attributes_for :payments, allow_destroy: true

  has_many :properties, through: :payments
  has_many :parks, through: :payments

  validates :name, presence: true, uniqueness: true

  geocoded_by :full_address

  after_validation :geocode,      if: -> { address_has_changed? || latitude.blank? || longitude.blank? }
  after_save :discard_payments,   if: -> { discarded_at.present? && discarded_at_before_last_save.nil? }
  after_save :undiscard_payments, if: -> { discarded_at.nil? && discarded_at_before_last_save.present? }

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

  private

  def discard_payments
    payments.each(&:discard)
  end

  def undiscard_payments
    self.reload
    payments.each(&:undiscard)
  end

end
