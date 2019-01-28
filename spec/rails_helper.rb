# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
# rubocop:disable Style/ExpandPathArguments
require File.expand_path('../../config/environment', __FILE__)
# rubocop:enable Style/ExpandPathArguments

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'spec_helper'
require 'rspec/rails'
require 'devise'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'webmock/rspec'
require 'support/form_helper'
require 'support/webmock_helper'
require 'database_cleaner'
require 'pundit/rspec'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Warden::Test::Helpers
  config.include FormHelper, type: :system
  config.include WebmockHelper

  # config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.file_fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.expect_with :rspec do |expectations|
    expectations.syntax = %i[should expect]
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = [:truncation, pre_count: true, reset_ids: true]
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
    Capybara.page.driver.browser.manage.window.resize_to(1920, 2024)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      Organization.create
      example.run
    end
  end

  config.after(:each) do
    Warden.test_reset!
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :active_record
    with.library :active_model
    with.library :action_controller
    with.library :rails
  end
end
