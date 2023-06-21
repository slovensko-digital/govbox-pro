source 'https://rubygems.org'

ruby '3.2.2'

gem 'rails', '~> 7.0'
gem 'rails-i18n'

gem 'pg', '~> 1.0'

gem 'puma', '~> 5.0'

gem 'turbo-rails'

# Styles
gem 'sprockets-rails'
gem 'importmap-rails'
gem 'tailwindcss-rails'
gem 'view_component'

# Schedulers
gem 'clockwork'

# Workers
gem 'good_job'

# Auth
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'pundit'

# Utilities
gem 'rest-client'
gem 'rack-attack'
gem 'rubyzip', require: 'zip'
gem 'jwt'
gem 'stimulus-rails'
gem 'jsbundling-rails'

# Monitoring
gem 'rollbar'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  gem 'dotenv-rails'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'foreman'
end

group :development do
  gem 'annotate'
  gem 'listen'
  gem 'web-console'
  gem 'solargraph'
  gem 'htmlbeautifier'
end

group :test do
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'webmock'
end
