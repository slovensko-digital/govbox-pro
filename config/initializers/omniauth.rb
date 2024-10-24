Rails.application.config.middleware.use OmniAuth::Builder do
  # TODO move to tenant config

  configure do |config|
    # Raise errors in every environment instead of redirecting to the default error page.
    config.failure_raise_out_environments = ['development', 'production', 'staging', 'test']

    # Respond to saml, saml/callback, saml/metadata, saml/slo, and saml/spslo under path prefix.
    config.path_prefix = '/auth'

    config.on_failure do |env|
      SessionsController.action(:destroy).call(env)
    end

    # Use default application logger.
    config.logger = Rails.logger
  end

  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], {
    scope: 'email'
  }

  provider :saml, UpvsEnvironment.sso_settings if UpvsEnvironment.sso_support?
end
