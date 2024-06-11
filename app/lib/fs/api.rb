module Fs
  class Api
    def initialize(url, api_connection: nil, box: nil, handler: Faraday)
      @url = url
      @handler = handler
      @handler.options.timeout = 900_000

      api_connection = box&.api_connection unless api_connection
      @sub = api_connection&.sub
      @api_token_private_key = api_connection ? OpenSSL::PKey::RSA.new(api_connection.api_token_private_key) : nil
      @fs_credentials = api_connection ? "#{api_connection.settings_username}:#{api_connection.settings_password}" : nil
      @obo = box ? "#{box.settings_subject_id}:#{box.settings_dic}" : nil
    end

    def fetch_forms(**args)
      request(:get, "forms", **args)
    end

    def get_public_key(**args)
      @fs_public_key ||= request(:get, "public-key")[:body]["public_key_b64"]
    end

    def get_subjects
      request(:get, "subjects", {}, jwt_header.merge(fs_credentials_header))[:body]
    end

    def fetch_sent_messages(page: 1, count: 100, obo: @obo)
      request(:get, "sent-messages", {}, jwt_header(obo).merge(fs_credentials_header))[:body]
    end

    def fetch_sent_message(message_id, obo: @obo)
      request(:get, "sent-messages/#{message_id}", {}, jwt_header(obo).merge(fs_credentials_header))[:body]
    end

    def fetch_received_messages(page: 1, count: 100, obo: @obo)
      request(:get, "received-messages", {}, jwt_header(obo).merge(fs_credentials_header))[:body]
    end

    def fetch_received_message(message_id, obo: @obo)
      request(:get, "received-messages/#{message_id}", {}, jwt_header(obo).merge(fs_credentials_header))[:body]
    end

    def post_validation(form_identifier, content)
      request(:post, "validations", {form_identifier: form_identifier, content: content}, jwt_header, accept_negative: true)
    end

    def delete_validation(validation_id)
      request(:delete, "validations/#{validation_id}", {}, jwt_header, accept_negative: true)
    end

    def post_submission(form_identifier, content, is_signed = true, mime_type = 'application/vnd.etsi.asic-e+zip', obo: @obo)
      request(:post, "submissions", {
        is_signed: is_signed,
        mime_type: mime_type,
        form_identifier: form_identifier,
        content: content
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
      token = Base64.strict_encode64 key.public_encrypt(Base64.strict_encode64 @fs_credentials)

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
      raise StandardError.new(response.body) unless accept_negative || response.status < 400
      return {
        status: response.status,
        body: structure,
        headers: response.headers
      }
    end
  end
end
