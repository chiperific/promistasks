# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Promisetasks
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.generators do |g|
      g.test_framework :rspec
    end

    config.active_job.queue_adapter = :delayed_job

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # In vanilla rails, this adds a div around each error field, but that screws with materializecss.
    # So I found a way to add the 'field_with_errors' class right to the field
    config.action_view.field_error_proc = proc do |html_tag, _instance|
      fragments = Nokogiri::HTML::DocumentFragment.parse(html_tag).css 'input, textarea, select'
      fragments.each do |f|
        f['class'] = 'field_with_errors'
      end
      fragments.to_html.html_safe
    end
  end
end
