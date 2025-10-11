source 'https://rubygems.org'

ruby '3.3.0'

gem 'rails', '~> 7.1'
gem 'rails-i18n'

gem 'pg', '~> 1.5'
gem 'with_advisory_lock'

gem 'puma', '~> 6.4'

gem 'turbo-rails'

# Styles
gem 'sprockets-rails'
gem 'importmap-rails'
gem 'initials'
gem 'tailwindcss-rails'
gem 'view_component'

# Schedulers
gem 'clockwork'

# Workers
gem 'good_job', '= 3.29.4'

# Auth
gem 'omniauth-google-oauth2'
gem 'omniauth-saml', '~> 2.2.1'
gem 'omniauth-rails_csrf_protection'
gem 'pundit'

# Utilities
gem 'rest-client'
gem 'rack-attack'
gem 'jbuilder'
gem 'rubyzip', require: 'zip'
gem 'jwt'
gem 'stimulus-rails'
gem 'jsbundling-rails'
gem 'pdf-reader'
gem 'grover'
gem 'caxlsx'

# Monitoring
gem 'rollbar'

# search
gem 'pg_search'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  gem "brakeman"
  gem 'dotenv-rails'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'foreman'
end

group :development do
  gem 'annotate'
  gem 'listen'
  gem 'web-console'
  gem 'htmlbeautifier'
  gem 'rdbg'
  gem 'rubocop-rails'
end

group :test do
  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'webmock'
  gem 'simplecov', require: false
end
