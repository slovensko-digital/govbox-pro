source 'https://rubygems.org'

ruby '4.0.6'

gem 'rails', '~> 8.1.4'
gem 'rails-i18n'

gem 'pg', '~> 1.1'
gem 'with_advisory_lock'

gem 'puma', '>= 5.0'

gem 'turbo-rails'

# Styles
gem 'sprockets-rails'
# sprockets 4.2.1 passes `create_additions` to JSON.parse, which json 3 (shipped
# with Ruby 4.0) rejects; it breaks booting with a precompiled asset manifest.
gem 'sprockets', '>= 4.4.1'
gem 'importmap-rails'
gem 'initials'
gem 'tailwindcss-rails'
gem 'view_component'

# Schedulers
gem 'clockwork'

# Workers
gem 'good_job'

# Auth
gem 'omniauth-identity'
gem 'omniauth-google-oauth2'
gem 'omniauth-microsoft_graph'
gem 'omniauth-saml'
gem 'omniauth-rails_csrf_protection', '>= 2.0' # 1.0.1 includes ActiveSupport::Configurable, deprecated in Rails 8.1 and removed in 8.2
gem 'pundit'

# Utilities
gem 'csv'
gem 'ostruct'
gem 'rest-client'
gem 'rack-attack'
gem 'jbuilder'
gem 'rubyzip', require: 'zip'
gem 'jwt'
gem 'stimulus-rails'
gem 'pdf-reader'
gem 'grover'
gem 'caxlsx'

# Monitoring
gem 'rollbar'

# search
gem 'pg_search'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

group :development, :test do
  gem "brakeman"
  gem 'dotenv-rails'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'foreman'
end

group :development do
  gem 'annotaterb'
  gem 'listen'
  gem 'web-console'
  gem 'htmlbeautifier'
  gem 'rdbg'
  gem 'rubocop-rails'
end

group :test do
  gem 'minitest'
  gem 'minitest-mock', require: false
  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'webmock'
  gem 'simplecov', require: false
end

gem "bcrypt", "~> 3.1.7"
