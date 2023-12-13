require 'test_helper'

class ApiEnvironmentTest < ActiveSupport::TestCase
  setup do
    @api_environment = ApiEnvironment
    @key_pair = OpenSSL::PKey::RSA.new(512)
  end

  test '.tenant_token_authenticator returns tenant token authenticator' do
    assert_respond_to @api_environment.tenant_token_authenticator, :verify_token
  end

  test '.site_admin_token_authenticator returns site_admin token authenticator' do
    assert_respond_to @api_environment.site_admin_token_authenticator, :verify_token
  end

  class SiteAdminTokenAuthenticatorTest < ApiEnvironmentTest
    test 'returns 0 for site_admin' do
      result = @api_environment.site_admin_token_authenticator.verify_token(generate_api_token)
      assert_equal 0, result
    end

    test 'fail on token verification with different key' do
      assert_raises(JWT::DecodeError) do
        @api_environment.site_admin_token_authenticator.verify_token(generate_api_token(key_pair: OpenSSL::PKey::RSA.new(512)))
      end
    end
  end

  class TenantTokenAuthenticatorTest < ApiEnvironmentTest
    test 'fails on token verification for non-existent tenant' do
      assert_raises(JWT::DecodeError) do
        @api_environment.tenant_token_authenticator.verify_token(generate_api_token(sub: 123))
      end
    end

    test 'fails on token verification for non-api tenant' do
      tenant = Tenant.new(name: "Test tenant")
      tenant.save

      assert_raises(JWT::DecodeError) do
        @api_environment.tenant_token_authenticator.verify_token(generate_api_token(sub: tenant.id))
      end
    end

    test 'fails on token verification for API box without public key' do
      tenant = Tenant.new(name: "Test tenant", feature_flags: [:api])
      tenant.save

      assert_raises(JWT::DecodeError) do
        @api_environment.tenant_token_authenticator.verify_token(generate_api_token(sub: tenant.id))
      end
    end

    test 'succeeds on token verification for tenant with API enabled and api_token_public_key present' do
      key_pair = OpenSSL::PKey::RSA.new(512)
      tenant = Tenant.new(name: "Test tenant", feature_flags: [:api], api_token_public_key: key_pair.public_key)
      tenant.save

      result = @api_environment.tenant_token_authenticator.verify_token(generate_api_token(sub: tenant.id, key_pair: key_pair))
      assert_equal tenant, result
    end

    test 'fails on token verification for tenant with different key' do
      tenant = Tenant.new(name: "Test tenant", feature_flags: [:api], api_token_public_key: OpenSSL::PKey::RSA.new(512).public_key)
      tenant.save

      assert_raises(JWT::DecodeError) do
        @api_environment.tenant_token_authenticator.verify_token(generate_api_token(sub: tenant.id, key_pair: OpenSSL::PKey::RSA.new(512)))
      end
    end
  end
end
