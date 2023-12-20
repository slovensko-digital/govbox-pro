module Archiver
  class ArchiverApi
    def initialize(url, handler: Faraday)
      @url = url
      @handler = handler
    end

    def validate_document(document_bytes)
      response = @handler.post("#{@url}validate", { content: Base64.strict_encode64(document_bytes) }.to_json)
      structure = response.body.empty? ? nil : JSON.parse(response.body)

      return nil if response.status == 422 || response.status == 400
      raise StandardError unless response.status == 200

      structure
    end

    def extend_document(document_bytes)
      response = @handler.post("#{@url}extend", { content: Base64.strict_encode64(document_bytes) }.to_json)
      structure = response.body.empty? ? nil : JSON.parse(response.body)

      return nil if response.status == 422 || response.status == 400
      raise StandardError unless response.status == 200

      structure['content']
    end
  end
end
