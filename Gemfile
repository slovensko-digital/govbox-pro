source 'https://rubygems.org'

ruby '3.3.0'

gem 'rails', '~> 7.1'
gem 'rails-i18n'

gem 'actioncable-enhanced-postgresql-adapter'
gem 'pg', '~> 1.5'
gem 'with_advisory_lock'

gem 'puma', '~> 6.4'

gem 'turbo-rails'

# Styles
gem 'importmap-rails'
gem 'sprockets-rails'
gem 'tailwindcss-rails'
gem 'view_component'

# Schedulers
gem 'clockwork'

# Workers
gem 'good_job'

# Auth
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-saml', '~> 2.2.1'
gem 'pundit'

# Utilities
gem 'grover'
gem 'jbuilder'
gem 'jsbundling-rails'
gem 'jwt'
gem 'pdf-reader'
gem 'rack-attack'
gem 'rest-client'
gem 'rubyzip', require: 'zip'
gem 'stimulus-rails'

# Monitoring
gem 'rollbar'

# search
gem 'pg_search'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  gem "brakeman"
  gem 'dotenv-rails'
  gem 'foreman'
  gem 'pry-byebug'
  gem 'pry-rails'
end

group :development do
  gem 'annotate'
  gem 'erb_lint'
  gem 'htmlbeautifier'
  gem 'listen'
  gem 'rdbg'
  gem 'rubocop'
  gem 'rubocop-rails'
  gem 'ruby-lsp'
  gem 'ruby-lsp-rails'
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'webmock'
end
