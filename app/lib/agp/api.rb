module Agp
  class Api
    def initialize(url, api_token_private_key:, sub:, settings: {}, handler: Faraday)
      @url = url
      @api_token_private_key = OpenSSL::PKey::RSA.new(api_token_private_key)
      @sub = sub
      @handler = handler
      @settings = settings
    end

    def generate_uuid_from_message_objects(message_objects)
      digest_input = message_objects.map { |mo| "#{mo.id}#{mo.updated_at}" }.sort.join
      digest = Digest::SHA256.hexdigest(digest_input)
      "#{digest[0..7]}-#{digest[8..11]}-#{digest[12..15]}-#{digest[16..19]}-#{digest[20..31]}"
    end

    def upload_bundle(bundle)
      body = {
        id: bundle.bundle_identifier,
        contracts: bundle.contracts.map do |contract|
          {
            id: contract.contract_identifier,
            title: contract.message_object.name,
            allowedMethods: [@settings["signature_with_timestamp"].present? ? "ts-qes" : "qes"],
            documents: [
              generate_document_body(contract.message_object)
            ],
            signatureParameters: generate_signature_parameters(contract.message_object)
          }
        end,
        webhook: {
          url: Rails.application.routes.url_helpers.agp_webhooks_url,
          method: "standard"
        }
      }

      request_post("bundles", body)
    end

    def destroy_bundle(bundle_id)
      request(:delete, "bundles/#{CGI.escape(bundle_id)}")
    end

    def retrieve_signed_contract(contract_id)
      r = request(:get, "contracts/#{CGI.escape(contract_id)}/signed_document")
      file_url = r[:body]["download_url"]
      begin
        file_response = @handler.get(file_url)
        file_response = @handler.get(file_response.headers["Location"]) if file_response.status == 302
        content_b64 = Base64.strict_encode64(file_response.body)
        r[:body].merge({ "content" => content_b64 })
      rescue StandardError => e
        Rails.logger.error("Failed to retrieve signed document: #{e.message}")
        { error: e.message }
      end
    end

    def retrieve_contract_status(contract_id)
      request(:get, "contracts/#{CGI.escape(contract_id)}/status")
    end

    private

    def request_post(path, body)
      response = Faraday.post(File.join(@url, "api/v1/", path), body.to_json, jwt_header.merge({ content_type: 'application/json' }))
      structure = response.body.empty? ? nil : JSON.parse(response.body)
    rescue StandardError => e
      raise(StandardError, e.response) if e.respond_to?(:response) && e.response

      raise e
    else
      raise(ConflictResponseError, response.body) if response.status == 409
      raise(StandardError, response.body) if response.status != 404 && response.status > 400

      {
        status: response.status,
        body: structure,
        headers: response.headers
      }
    end

    def request(method, path, *args)
      request_url(method, File.join(@url, "api/v1/", path), *args, jwt_header.merge({ content_type: 'application/json' }))
    end

    def generate_document_body(mo)
      r = {}
      r[:filename] = mo.name
      r[:xdcParameters] = generate_xdc_parameters(mo) if mo.object_type == "FORM"

      if mo.mimetype.include?("base64")
        r[:contentType] = mo.mimetype
        r[:content] = mo.message_object_datum.blob
      else
        r[:contentType] = "#{mo.mimetype};base64"
        r[:content] = Base64.strict_encode64(mo.message_object_datum.blob)
      end

      r
    end

    def generate_xdc_parameters(mo)
      form = mo&.message&.form
      raise "Message form not found" unless form

      r = {
        autoLoadEform: true
      }

      r[:fsFormIdentifier] = form.identifier if form.is_a?(Fs::Form)

      r
    end

    def generate_signature_parameters(message_object)
      r = {
        level: "BASELINE_#{@settings["signature_with_timestamp"].present? ? "T" : "B"}"
      }

      if message_object.mimetype.include?("application/pdf")
        r[:format] = @settings["pdf_signature_format"]
        r[:container] = "ASiC_E" unless @settings["pdf_signature_format"] == "PAdES"
      else
        r[:format] = "XAdES"
        r[:container] = "ASiC_E"
      end

      r
    end

    def jwt_header
      token = JWT.encode(
        {
          sub: @sub,
          exp: 5.minutes.from_now.to_i,
          jti: SecureRandom.uuid
        },
        @api_token_private_key,
        'RS256'
      )

      { Authorization: "Bearer #{token}" }
    end

    def request_url(method, path, *args)
      response = @handler.public_send(method, path, *args)
      structure = response.body.empty? ? nil : JSON.parse(response.body)
    rescue StandardError => e
      raise(StandardError, e.response) if e.respond_to?(:response) && e.response

      raise e
    else
      raise(ConflictResponseError, response.body) if response.status == 409
      raise(StandardError, response.body) if response.status != 404 && response.status > 400

      {
        status: response.status,
        body: structure,
        headers: response.headers
      }
    end
  end

  class ConflictResponseError < StandardError
  end
end
