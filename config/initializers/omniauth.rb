# frozen_string_literal: true

OmniAuth.config.logger = Rails.logger

OmniAuth.config.full_host = Rails.env.production? ? Rails.application.credentials.full_host : 'http://localhost:3000'
