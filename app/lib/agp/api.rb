module Agp
  class Api
    class Error < StandardError; end
    class ConflictError < Error; end

    OPEN_TIMEOUT = 5
    TIMEOUT = 60
    MAX_REDIRECTS = 3

    def initialize(url, api_token_private_key:, sub:, settings: {}, handler: Faraday)
      @url = url
      @api_token_private_key = OpenSSL::PKey::RSA.new(api_token_private_key)
      @sub = sub
      @handler = handler
      @settings = settings
    end

    def upload_bundle(bundle, webhook_url:)
      body = {
        id: bundle.bundle_identifier,
        publiclyVisible: true,
        contracts: bundle.contracts.map do |contract|
          {
            id: contract.contract_identifier,
            allowedMethods: [@settings["signature_with_timestamp"].present? ? "ts-qes" : "qes"],
            documents: [
              generate_document_body(contract.message_object)
            ],
            signatureParameters: generate_signature_parameters(contract.message_object)
          }
        end,
        webhook: {
          url: webhook_url,
          method: "standard"
        }
      }

      request(:post, "bundles", body)
    end

    def destroy_bundle(bundle_id)
      request(:delete, "bundles/#{CGI.escape(bundle_id)}")
    end

    # Returns nil when AGP does not know the bundle (anymore).
    def retrieve_bundle(bundle_id)
      request(:get, "bundles/#{CGI.escape(bundle_id)}", allow_not_found: true)
    end

    # Returns nil while the contract is not signed.
    def retrieve_signed_document(contract_id)
      signed_document = request(:get, "contracts/#{CGI.escape(contract_id)}/signed_document", allow_not_found: true)

      download_signed_document(signed_document) if signed_document
    end

    def download_signed_document(signed_document)
      {
        filename: signed_document.fetch("filename"),
        content_type: signed_document.fetch("content_type"),
        content: download(signed_document.fetch("download_url"))
      }
    end

    private

    def request(method, path, body = nil, allow_not_found: false)
      headers = { "Authorization" => "Bearer #{jwt_token}", "Content-Type" => "application/json", "Accept" => "application/json" }
      response = connection.run_request(method, path, body&.to_json, headers)

      return if allow_not_found && response.status == 404
      raise ConflictError, response.body if response.status == 409
      raise Error, "AGP API #{method.upcase} #{path} failed with status #{response.status}: #{response.body}" unless response.success?

      response.body.presence && JSON.parse(response.body)
    end

    def download(url)
      MAX_REDIRECTS.succ.times do
        response = @handler.get(url) do |request|
          request.options.open_timeout = OPEN_TIMEOUT
          request.options.timeout = TIMEOUT
        end

        return response.body if response.success?
        raise Error, "Download of signed document failed with status #{response.status}" unless response.status.in?(300..399) && response.headers["Location"].present?

        url = URI.join(url, response.headers["Location"]).to_s
      end

      raise Error, "Download of signed document failed: too many redirects"
    end

    def connection
      @connection ||= @handler.new(url: File.join(@url, "api/v1/")) do |faraday|
        faraday.options.open_timeout = OPEN_TIMEOUT
        faraday.options.timeout = TIMEOUT
      end
    end

    def generate_document_body(mo)
      r = {}
      r[:filename] = mo.name
      r[:xdcParameters] = generate_xdc_parameters(mo) if mo.object_type == "FORM"

      if mo.mimetype.include?("base64")
        r[:contentType] = mo.mimetype.gsub("application/x-eform-xml", "application/xml")
        r[:content] = mo.message_object_datum.blob
      else
        r[:contentType] = "#{mo.mimetype.gsub("application/x-eform-xml", "application/xml")};base64"
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

    def jwt_token
      JWT.encode(
        {
          sub: @sub,
          exp: 5.minutes.from_now.to_i,
          jti: SecureRandom.uuid
        },
        @api_token_private_key,
        'RS256'
      )
    end
  end
end
