require 'jwt'

module Upvs
  class GovboxApi < Api
    attr_reader :sub, :obo, :api_token_private_key, :url, :edesk, :sktalk, :cep

    def initialize(url, box:, handler: Faraday)
      raise "Box API connection is not of type Govbox API connection" unless (box.api_connection.is_a?(::Govbox::ApiConnection) || box.api_connection.is_a?(::Govbox::ApiConnectionWithOboSupport))

      @sub = box.api_connection.sub
      @obo = box.api_connection.box_obo(box)
      @api_token_private_key = OpenSSL::PKey::RSA.new(box.api_connection.api_token_private_key)
      @url = url
      @edesk = Edesk.new(self)
      @sktalk = SkTalk.new(self)
      @cep = Cep.new(self)
      @handler = handler
      @handler.options.timeout = 900_000
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
        response_status, response_body = @api.request(:post, "#{@api.url}/api/sktalk/receive_and_save_to_outbox", data.to_json, header)
        [submit_successful?(response_status, response_body['receive_result'], response_body['save_to_outbox_result']), response_status, response_body]
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

    class Cep < Namespace
      def sign(data, api_connection)
        cep_sk_api = Upvs::SkApiClient.new.api(api_connection: api_connection).cep
        cep_sk_api.sign(data)
      end

      def sign_v2(data, api_connection)
        cep_sk_api = Upvs::SkApiClient.new.api(api_connection: api_connection).cep
        cep_sk_api.sign_v2(data)
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
