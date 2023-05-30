module Upvs
  class Api
    def request(method, path, *args)
      response = @handler.public_send(method, path, *args)
      structure = response.body.empty? ? nil : JSON.parse(response.body)
    rescue StandardError => error
      raise Error.new(error.response) if error.respond_to?(:response) && error.response
      raise error
    else
      return [response.status, structure]
    end

    class Namespace
      def initialize(api)
        @api = api
      end

      def authorization_payload
        "Bearer #{token}"
      end

      def token
        JWT.encode({ sub: @api.sub, exp: 5.minutes.from_now.to_i, jti: SecureRandom.uuid }, @api.api_token_private_key, 'RS256')
      end
    end

    class Error < StandardError
      attr_accessor :resource

      attr_reader :response

      def initialize(response)
        @response = response
      end

      def to_s
        cause ? cause.to_s : 'Unknown error'
      end
    end
  end
end
