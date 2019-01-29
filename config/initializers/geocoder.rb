# frozen_string_literal: true

# https://github.com/alexreisner/geocoder/blob/master/README_API_GUIDE.md
Geocoder.configure(
  lookup: :google,
  use_https: true,
  api_key: Rails.application.credentials.google_geocode_api_key
)
