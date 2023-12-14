module Archiver
  class ArchiverApi
    def initialize(url, handler: Faraday)
      @url = url
      @handler = handler
    end

    def validate_document(document_bytes)
      response = @handler.public_send(:post, "#{@url}validate", { content: Base64.strict_encode64(document_bytes) }.to_json)
      structure = response.body.empty? ? nil : JSON.parse(response.body)
    rescue StandardError => e
      raise Error, e.response if e.respond_to?(:response) && e.response

      raise e
    else
      [response.status, structure]
    end
  end
end
