# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.0'

gem 'bootsnap', '>= 1.4.2', require: false
gem 'bcrypt', '~> 3.1.7'
gem 'coffee-rails'
# gem 'devise'
gem 'google-api-client'
gem 'haml'
gem 'jquery-rails'
gem 'materialize-sass'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection', '~> 0.1'
gem 'pg'
gem 'puma'
gem 'rails', '>= 6.0'
gem 'spring'
gem 'sass-rails'
gem 'turbolinks'
gem 'webpacker', '~> 4.0'

group :development, :test do
  gem 'better_errors'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'foreman'
  gem 'rubocop'
end

group :development do
  gem 'listen', '~> 3.2'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
