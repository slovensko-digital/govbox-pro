# frozen_string_literal: true

module Fs
  class AdminApi
    def initialize(url, sub, private_key, handler: Faraday)
      @url = url
      @handler = handler
      @handler.options.timeout = 900_000

      @sub = sub
      @api_token_private_key = OpenSSL::PKey::RSA.new(private_key)
    end

    def create_user(crm_identifier:, api_token_public_key:)
      request(:post, "users", {
        crm_identifier: crm_identifier,
        api_token_public_key: api_token_public_key
      }.to_json, jwt_header.merge({"Content-Type": "application/json"}))
    end

    private

    def jwt_header(obo = nil)
      token = JWT.encode({
          sub: @sub,
          aud: "/api/v1/admin/",
          exp: 5.minutes.from_now.to_i,
          jti: SecureRandom.uuid
        }.merge(obo ? {obo: obo} : {}),
        @api_token_private_key,
        'RS256'
      )

      { "Authorization": "Bearer #{token}" }
    end

    def request(method, path, *args, accept_negative: false)
      request_url(method, "#{@url}/api/v1/admin/#{path}", *args, accept_negative: accept_negative)
    end

    def request_url(method, path, *args, accept_negative: false)
      response = @handler.public_send(method, path, *args)
      structure = response.body.empty? ? nil : JSON.parse(response.body)
    rescue StandardError => error
      raise StandardError.new(error.response) if error.respond_to?(:response) && error.response
      raise error
    else
      raise StandardError.new(response.body) if !accept_negative && response.status != 404 && response.status > 400
      return {
        status: response.status,
        body: structure,
        headers: response.headers
      }
    end
  end
end
