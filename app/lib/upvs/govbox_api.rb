require 'jwt'

module Upvs
  class GovboxApi < Api
    attr_reader :sub, :obo, :api_token_private_key, :url, :edesk, :sktalk

    def initialize(url, box:, handler: Faraday)
      @sub = box.api_connection.sub
      @obo = box.api_connection.box_obo(box)
      @api_token_private_key = OpenSSL::PKey::RSA.new(box.api_connection.api_token_private_key)
      @url = url
      @edesk = Edesk.new(self)
      @sktalk = SkTalk.new(self)
      @handler = handler
      @handler.options.timeout = 900_000
    end

    class Edesk < Namespace
      def fetch_folders
        @api.request(:get, "#{@api.url}/api/edesk/folders", {}, header)
      end

      def fetch_messages(folder_id, page: 1, count: 5000)
        @api.request(:get, "#{@api.url}/api/edesk/folders/#{folder_id}/messages?page=#{page}&per_page=#{count}", {}, header)
      end

      def fetch_message(message_id)
        @api.request(:get, "#{@api.url}/api/edesk/messages/#{message_id}", {}, header)
      end

      def authorize_delivery_notification(authorization_url, mode: :async)
        params = (mode == :sync ? { async: false } : {})
        response_status, response_body = @api.request(:post, authorization_url, params, header)
        [authorization_successful?(response_status, response_body['code']), response_body['message_id']]
      end

      private

      def header
        {
          "Authorization": authorization_payload
        }
      end

      def authorization_successful?(response_status, authorization_code)
        response_status == 200 && authorization_code == 0
      end
    end

    class SkTalk < Namespace
      def receive_and_save_to_outbox(data)
        response_status, response_body = @api.request(:post, receive_and_save_to_outbox_url, data.to_json, header)
        [submit_successful?(response_status, response_body['receive_result'], response_body['save_to_outbox_result']), response_status, response_body]
      end

      def receive_and_save_to_outbox_url
        "#{@api.url}/api/sktalk/receive_and_save_to_outbox"
      end

      private

      def header
        {
          "Authorization": authorization_payload,
          "Content-Type": "application/vnd.sktalk+json;type=SkTalk"
        }
      end

      def submit_successful?(response_status, receive_result, save_to_outbox_result)
        response_status == 200 && receive_result == 0 && save_to_outbox_result == 0
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
