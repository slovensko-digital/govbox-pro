source 'https://rubygems.org'

ruby '3.2.2'

gem 'rails', '~> 7.0'
gem 'rails-i18n'

gem 'pg', '~> 1.0'

gem 'puma', '~> 5.0'

# Styles
gem 'sass-rails', '>= 6'
gem 'bootstrap', '4.0.0.alpha6'

# Schedulers
gem 'clockwork'

# Workers
gem "good_job"

# Auth
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

# Utilities
gem 'rest-client'
gem 'rack-attack'
gem 'rubyzip', require: 'zip'
gem 'jwt'

# Monitoring
gem 'rollbar'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  gem 'dotenv-rails'
  gem 'pry-rails'
  gem 'pry-byebug'
end

group :development do
  gem 'annotate'
  gem 'listen'
  gem 'web-console'
end

group :test do
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'webmock'
end
