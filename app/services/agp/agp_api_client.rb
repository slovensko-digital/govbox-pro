module Agp
  class AgpApiClient
    def api(tenant:)
      Agp::Api.new(tenant.agp_api_url, api_token_private_key: tenant.agp_api_token_private_key, sub: tenant.agp_sub, settings: tenant.signature_settings)
    end
  end
end
