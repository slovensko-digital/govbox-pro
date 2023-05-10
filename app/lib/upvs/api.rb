module Upvs
  class Api
    def request(method, path, *args)
      response = @handler.public_send(method, path, *args)
      structure = response.body.empty? ? nil : JSON.parse(response.body)
    rescue StandardError => error
      raise Error.new(error.response) if error.respond_to?(:response) && error.response
      raise error
    else
      raise Error.new(response), 'Status not OK' if response.code != 200
      return structure
    end

    class Namespace
      def initialize(api)
        @api = api
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
