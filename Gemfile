# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.6.3' # '2.4.5'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'coffee-rails', '~> 5'
gem 'delayed_cron_job'
gem 'delayed_job_active_record'
gem 'delayed_job_progress'
gem 'devise'
gem 'discard', '~> 1.0'
gem 'geocoder'
# gem 'google-api-client' # use instead of HTTParty when I can figure it out
gem 'httparty'
gem 'jbuilder', '~> 2.5'
gem 'jquery-datatables'
gem 'jquery-rails'
gem 'libv8',  '6.7.288.46.1'
gem 'materialize-sass'
gem 'mini_racer'
gem 'money-rails'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection', '~> 0.1'
gem 'pg'
gem 'puma', '~> 3.7'
gem 'pundit'
gem 'rails', '>= 5.2'
gem 'sass-rails', '~> 5.0'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
gem 'webmock', git: 'https://github.com/bblimke/webmock.git', branch: 'master'

group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'foreman'
  gem 'letter_opener_web'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'pry-remote'
  gem 'rubocop'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'capybara'
  gem 'capybara-slow_finder_errors'
  gem 'database_cleaner'
  gem 'faker'
  gem 'launchy'
  gem 'rails-controller-testing'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
end

group :development do
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
