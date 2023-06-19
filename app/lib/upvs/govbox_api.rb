require 'jwt'

module Upvs
  class GovboxApi < Api
    attr_reader :sub, :api_token_private_key, :url, :edesk, :sktalk

    def initialize(url, govbox_api_connection, handler: Faraday)
      @sub = govbox_api_connection.sub
      @obo = govbox_api_connection.obo
      @api_token_private_key = OpenSSL::PKey::RSA.new(govbox_api_connection.api_token_private_key)
      @url = url
      @edesk = Edesk.new(self)
      @sktalk = SkTalk.new(self)
      @handler = handler
      @handler.options.timeout = 900000
    end

    class Edesk < Namespace
      def fetch_folders
        @api.request(:get, "#{@api.url}/api/edesk/folders", {}, header)
      end

      def fetch_messages(folder_id, offset: 0, count: 5000)
        @api.request(:get, "#{@api.url}/api/edesk/folders/#{folder_id}/messages?page=#{offset}&per_page=#{count}", {}, header)
      end

      def fetch_message(message_id)
        @api.request(:get, "#{@api.url}/api/edesk/messages/#{message_id}", {}, header)
      end

      private

      def header
        {
          "Authorization": authorization_payload,
        }
      end
    end

    class SkTalk < Namespace
      def receive_and_save_to_outbox(data)
        response_status, response_body = @api.request(:post, "#{@api.url}/api/sktalk/receive_and_save_to_outbox", data.to_json, header)
        [response_status, response_body['receive_result'], response_body['save_to_outbox_result']]
      end

      private

      def header
        {
          "Authorization": authorization_payload,
          "Content-Type": "application/vnd.sktalk+json;type=SkTalk"
        }
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
