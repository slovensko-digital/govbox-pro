source 'https://rubygems.org'

ruby '4.0.6'

gem 'rails', '~> 8.1.4'
gem 'rails-i18n', '~> 8.0'

gem 'pg', '~> 1.5'
gem 'with_advisory_lock'

gem 'puma', '~> 6.4'

gem 'turbo-rails'

# Styles
gem 'sprockets-rails'
# sprockets 4.2.1 passes `create_additions` to JSON.parse, which json 3 (shipped
# with Ruby 4.0) rejects; it breaks booting with a precompiled asset manifest.
gem 'sprockets', '>= 4.4.1'
gem 'importmap-rails'
gem 'initials'
gem 'tailwindcss-rails', '~> 4.6'

# Schedulers
gem 'clockwork'

# Workers
gem 'good_job'

# Auth
gem 'omniauth-identity'
gem 'omniauth-google-oauth2'
gem 'omniauth-microsoft_graph'
gem 'omniauth-saml', '~> 2.2.1'
gem 'omniauth-rails_csrf_protection'
gem 'pundit'

# Utilities
gem 'csv'
gem 'ostruct'
gem 'rest-client'
gem 'rack-attack'
gem 'rack-session', '>= 2.1.2'
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
gem 'bootsnap', '>= 1.4.4', require: false

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
  gem 'minitest', '~> 6.0'
  gem 'minitest-mock', '~> 5.27', require: false
  gem 'selenium-webdriver', '~> 4.41'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'webmock'
  gem 'simplecov', require: false
end

gem "bcrypt", "~> 3.1"
