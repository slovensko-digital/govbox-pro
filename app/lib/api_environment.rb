module ApiEnvironment
  def self.tenant_token_authenticator
    @tenant_token_authenticator ||= ApiTokenAuthenticator.new(
      public_key_reader: API_TENANT_PUBLIC_KEY_READER,
      return_handler: API_TENANT_BY_IDENTITY_FINDER,
    )
  end

  def self.site_admin_token_authenticator
    @site_admin_token_authenticator ||= ApiTokenAuthenticator.new(
      public_key_reader: API_SITE_ADMIN_PUBLIC_KEY_READER,
      return_handler: -> (sub) { true },
    )
  end

  API_TENANT_PUBLIC_KEY_READER = -> (sub) { OpenSSL::PKey::RSA.new(API_TENANT_BY_IDENTITY_FINDER.call(sub).api_token_public_key) }
  API_TENANT_BY_IDENTITY_FINDER = -> (sub) do
    raise unless sub&.to_i

    tenant = Tenant.find(sub&.to_i)

    raise unless tenant
    raise unless tenant.feature_enabled? :api

    tenant
  end

  API_SITE_ADMIN_PUBLIC_KEY_READER = -> (sub) { OpenSSL::PKey::RSA.new(ENV.fetch('SITE_ADMIN_API_PUBLIC_KEY')) }
end
