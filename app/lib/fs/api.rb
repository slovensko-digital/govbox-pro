module Fs
  class Api
    def initialize(url, box: , handler: Faraday)
      @url = url
      @handler = handler
      @handler.options.timeout = 900_000
      @sub = box&.api_connection.sub
      @api_token_private_key = box ? OpenSSL::PKey::RSA.new(box.api_connection.api_token_private_key) : nil
      @fs_credentials = box&.api_connection.fs_credentials
    end

    def fetch_forms(*args)
      request(:get, "forms", **args)
    end

    def get_public_key(*args)
      @fs_public_key ||= request(:get, "public-key")[1][:public_key_b64]
    end

    def get_subjects
      request(:get, "subjects", {}, jwt_header)
    end

    def fetch_sent_messages(obo, page: 1, count: 100)
      request(:get, "sent-messages", {}, jwt_header(obo).merge fs_credentials_header)
    end

    def fetch_sent_message(obo, message_id)
      request(:get, "sent-messages/#{message_id}", {}, jwt_header(obo).merge fs_credentials_header)
    end

    def fetch_received_messages(obo, page: 1, count: 100)
      request(:get, "received-messages", {}, jwt_header(obo).merge fs_credentials_header)
    end

    def fetch_received_message(obo, message_id)
      request(:get, "received-messages/#{message_id}", {}, jwt_header(obo).merge fs_credentials_header)
    end

    def post_validation(form_identifier, content)
      request(:post, "validations", {form_identifier: form_identifier, content: content}, jwt_header)
    end

    def delete_validation(validation_id)
      request(:delete, "validations/#{validation_id}", {}, jwt_header)
    end

    def post_submission(obo, form_identifier, content, is_signed = true, mime_type = "applicaiton/xml")
      request(:post, "submissions", {
        is_signed: is_signed,
        mime_type: mime_type,
        form_identifier: form_identifier,
        content: content
      }, jwt_header(obo).merge fs_credentials_header)
    end

    def delete_submission(submission_id)
      request(:delete, "submissions/#{submission_id}", {}, jwt_header)
    end

    def wait_for_result(response)
      while response[:headers][:location]
        response = request_url(:get, response[:headers][:location], {}, jwt_header)
        sleep response[:headers][:retry_after] if response[:headers][:retry_after]
      end

      response
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
      token = Base64.strict_encode64 key.public_encrypt(@fs_credentials)

      { "X-FS-Authorization": "Bearer #{token}" }
    end

    def request(method, path, *args)
      request_url(method, "#{@url}/api/v1/#{path}", *args)
    end

    def request_url(method, path, *args)
      response = @handler.public_send(method, path, *args)
      structure = response.body.empty? ? nil : JSON.parse(response.body)
    rescue StandardError => error
      raise Error.new(error.response) if error.respond_to?(:response) && error.response
      raise error
    else
      raise Error.new(response) unless response.status < 400
      return {
        status: response.status,
        body: structure,
        headers: response.headers
      }
    end
  end
end
