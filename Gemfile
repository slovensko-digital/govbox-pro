source 'https://rubygems.org'

ruby '3.3.0'

gem 'rails', '~> 7.1'
gem 'rails-i18n'

gem 'pg', '~> 1.0'
gem 'with_advisory_lock'

gem 'puma', '~> 6.0'

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
gem 'omniauth-saml', '~> 2.1.0'
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
  gem 'solargraph'
  gem 'htmlbeautifier'
  gem 'erb_lint'
  gem 'ruby-lsp-rails'
  gem 'rdbg'
  gem 'rubocop'
  gem 'rubocop-rails'
end

group :test do
  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'webmock'
  gem 'simplecov', require: false
end
