require 'jwt'

module Upvs
  class GovboxApi < Api
    attr_reader :sub, :api_token_private_key, :url, :edesk, :sktalk

    def initialize(sub, url: ENV['GB_API_URL'], handler: Faraday)
      @sub = sub
      @api_token_private_key = load_api_token_private_key
      @url = url
      @edesk = Edesk.new(self)
      @sktalk = SkTalk.new(self)
      @handler = handler
    end

    class Edesk < Namespace

    end

    class SkTalk < Namespace
      def receive_and_save_to_outbox(data)
        response = @api.request(:post, "#{@api.url}/api/sktalk/receive_and_save_to_outbox", data.to_json, header)
        receive_and_save_to_outbox_successful?(response)
      end

      private

      def header
        {
          "Authorization": authorization_payload,
          "Content-Type": "application/vnd.sktalk+json;type=SkTalk"
        }
      end

      def authorization_payload
        "Bearer #{token}"
      end

      def token
        JWT.encode({ sub: @api.sub, exp: 5.minutes.from_now.to_i, jti: SecureRandom.uuid }, @api.api_token_private_key, 'RS256')
      end

      def receive_and_save_to_outbox_successful?(response)
        success = response['receive_result'] == 0 && response['save_to_outbox_result'] == 0

        raise Error.new(response), 'Receive and save to outbox fail' unless success

        success
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

    private

    def load_api_token_private_key
      private_key_path = Rails.root.join('security', "govbox_api_#{ENV['GB_API_ENV']}.pem").to_s
      OpenSSL::PKey::RSA.new(File.read(private_key_path))
    end
  end
end
