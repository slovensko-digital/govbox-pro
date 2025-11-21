module Agp
  class AgpApiClient
    def initialize(host: ENV.fetch('AGP_API_URL'))
      @host = host
    end

    def api(tenant:)
      Agp::Api.new(@host, api_token_private_key: Base64.decode64(ENV.fetch("AGP_API_TOKEN_PRIVATE_KEY")), sub: tenant.agp_sub, settings: tenant.signature_settings)
    end
  end
end
