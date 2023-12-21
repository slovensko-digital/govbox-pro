require 'jwt'

module Upvs
  class SkApi < Api
    attr_reader :sub, :obo, :api_token_private_key, :url, :cep

    def initialize(url, box:, handler: Faraday)
      raise "Box API connection is not of type SK API connection" unless box.api_connection.is_a?(::SkApi::ApiConnectionWithOboSupport)

      @sub = box.api_connection.sub
      @obo = box.api_connection.box_obo(box)
      @api_token_private_key = OpenSSL::PKey::RSA.new(box.api_connection.api_token_private_key)
      @url = url
      @cep = Cep.new(self)
      @handler = handler
      @handler.options.timeout = 900_000
    end

    class Cep < Namespace
      def sign(data)
        response_status, response_body = @api.request(:post, "#{@api.url}/api/cep/sign", data.to_json, header)
        response_body['signed_objects'] if sign_successful?(response_status, response_body)
      end

      def sign_v2(data)
        response_status, response_body = @api.request(:post, "#{@api.url}/api/cep/sign_v2", data.to_json, header)
        response_body['signed_object_groups'] if sign_successful?(response_status, response_body)
      end

      private

      def header
        {
          "Authorization": authorization_payload,
          "Content-Type": "application/json"
        }
      end

      def sign_successful?(response_status, response_body)
        response_status == 200 && response_body['sign_description'] == 'OK'
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
