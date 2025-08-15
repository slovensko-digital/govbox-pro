# frozen_string_literal: true

module Fs
  class Api
    attr_accessor :obo, :obo_without_delegate

    def initialize(url, api_connection: nil, box: nil, handler: Faraday)
      @url = url
      @handler = handler
      @handler.options.timeout = 900_000

      api_connection ||= box&.api_connection
      @sub = api_connection&.sub
      @api_token_private_key = api_connection ? OpenSSL::PKey::RSA.new(api_connection.api_token_private_key) : nil
      @fs_credentials = api_connection ? "#{api_connection.settings_username}:#{api_connection.settings_password}" : nil

      initialize_obo(box, api_connection: api_connection) if box
    end

    def fetch_forms(**args)
      request(:get, "forms", **args)
    end

    def parse_form(content)
      request(:post, "forms/parse", { content: Base64.strict_encode64(content) })[:body]
    end

    def get_public_key(**args)
      @fs_public_key ||= request(:get, "public-key")[:body]["public_key_b64"]
    end

    def get_subjects
      request(:get, "subjects", {}, jwt_header.merge(fs_credentials_header))[:body]
    end

    def fetch_sent_messages(page: 1, count: 100, obo: @obo)
      request(:get, "sent-messages?page=#{page}&per_page=#{count}", {}, jwt_header(obo).merge(fs_credentials_header))[:body]
    end

    def fetch_sent_message(message_id, obo: @obo)
      request(:get, "sent-messages/#{CGI.escape(message_id)}", {}, jwt_header(obo).merge(fs_credentials_header))[:body]
    end

    def fetch_received_messages(sent_message_id: nil, page: 1, count: 100, from: nil, to: nil, obo: @obo)
      query = { sent_message_id: sent_message_id, page: page, per_page: count, from: from, to: to }.compact.to_query

      request(:get, "received-messages?#{query}", {}, jwt_header(obo).merge(fs_credentials_header))[:body]
    end

    def fetch_received_message(message_id, obo: @obo)
      request(:get, "received-messages/#{CGI.escape(message_id)}", {}, jwt_header(obo).merge(fs_credentials_header))[:body]
    end

    def post_validation(form_identifier, content)
      request(:post, "validations", {form_identifier: form_identifier, content: content}, jwt_header, accept_negative: true)
    end

    def delete_validation(validation_id)
      request(:delete, "validations/#{validation_id}", {}, jwt_header, accept_negative: true)
    end

    def post_submission(form_identifier, content, allow_warn_status: true, message_uuid:, form_object_uuid:, is_signed: true, mime_type: 'application/vnd.etsi.asic-e+zip', obo: @obo)
      request(:post, "submissions", {
        message_container_message_id: message_uuid,
        message_container_form_object_id: form_object_uuid,
        is_signed: is_signed,
        mime_type: mime_type,
        form_identifier: form_identifier,
        content: content,
        allow_warn_status: allow_warn_status
      }, jwt_header(obo).merge(fs_credentials_header))
    end

    def submission_url
      "#{@url}/api/v1/submissions"
    end

    def delete_submission(submission_id)
      request(:delete, "submissions/#{submission_id}", {}, jwt_header)
    end

    def get_location(location_header)
      request_url(:get, location_header, {}, jwt_header, accept_negative: true)
    end

    private

    def initialize_obo(box, api_connection:)
      @obo_without_delegate = "#{box.settings_subject_id}:#{box.settings_dic}"
      delegate_id = box.boxes_api_connections.find_by(api_connection: api_connection).settings_delegate_id
      @obo = @obo_without_delegate + ( delegate_id ? ":#{delegate_id}" : "")
    end

    def jwt_header(obo = nil)
      token = JWT.encode({
          sub: @sub,
          exp: 5.minutes.from_now.to_i,
          jti: SecureRandom.uuid
        }.merge(obo ? {obo: obo} : {}),
        @api_token_private_key,
        'RS256'
      )

      { "Authorization": "Bearer #{token}" }
    end

    def fs_credentials_header
      key = OpenSSL::PKey::RSA.new(Base64.decode64 get_public_key)
      token = Base64.strict_encode64 key.encrypt(Base64.strict_encode64 @fs_credentials)

      { "X-FS-Authorization": "Bearer #{token}" }
    end

    def request(method, path, *args, accept_negative: false)
      request_url(method, "#{@url}/api/v1/#{path}", *args, accept_negative: accept_negative)
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
