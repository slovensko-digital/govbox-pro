require 'simplecov'
SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

Rails.application.eager_load! # see https://github.com/simplecov-ruby/simplecov?tab=readme-ov-file#want-to-use-spring-with-simplecov

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

def generate_api_token(sub: 'site_admin', exp: 5.minutes.since(Time.now).to_i, jti: SecureRandom.uuid, key_pair: default_key_pair, **payload)
  JWT.encode(payload.merge(sub: sub, exp: exp, jti: jti).compact, key_pair, 'RS256')
end

def safe_click
  5.times do
    element = yield.inspect
    break if element != "Obsolete #<Capybara::Node::Element>"
  end
end

private

def default_key_pair
  OpenSSL::PKey::RSA.new File.read 'test/fixtures/site_admin_test_cert.pem'
end
