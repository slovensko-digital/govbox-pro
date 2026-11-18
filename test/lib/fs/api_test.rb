# frozen_string_literal: true

require 'test_helper'

module Fs
  class ApiTest < ActiveSupport::TestCase
    FS_API_URL = ENV.fetch('FS_API_URL')

    test "box with delegate_id should create Fs::Api object that uses delegate_id in obo in fetch_sent_messages" do
      handler = Minitest::Mock.new
      handler.expect :public_send, OpenStruct.new({
        body: '{"ok": true}', status: 200, headers: ""
      }), [:get, "#{FS_API_URL}/api/v1/sent-messages?page=1&per_page=100", {}, {}]

      box = boxes(:fs_delegate)
      fs_api = Fs::Api.new(FS_API_URL, box: box, handler: handler)

      jwt_header_mock = Minitest::Mock.new
      jwt_header_mock.expect :call, {}, ["#{box.settings_subject_id}:#{box.settings_dic}:#{box.boxes_api_connections.first.settings_delegate_id}"]

      fs_api.stub :fs_credentials_header, {} do
        fs_api.stub :jwt_header, jwt_header_mock do
          fs_api.fetch_sent_messages
        end
      end

      assert_mock jwt_header_mock
      assert_mock handler
    end

    test "box without delegate_id should create Fs::Api object that uses valid obo in fetch_sent_messages" do
      handler = Minitest::Mock.new
      handler.expect :public_send, OpenStruct.new({
        body: '{"ok": true}', status: 200, headers: ""
      }), [:get, "#{FS_API_URL}/api/v1/sent-messages?page=1&per_page=100", {}, {}]

      box = boxes(:fs_accountants)
      fs_api = Fs::Api.new(FS_API_URL, box: box, handler: handler)

      jwt_header_mock = Minitest::Mock.new
      jwt_header_mock.expect :call, {}, ["#{box.settings_subject_id}:#{box.settings_dic}"]

      fs_api.stub :fs_credentials_header, {} do
        fs_api.stub :jwt_header, jwt_header_mock do
          fs_api.fetch_sent_messages
        end
      end

      assert_mock jwt_header_mock
      assert_mock handler
    end

    test "raises authentication error for unauthorized response" do
      handler = auth_error_handler(status: 401, body: "bad credentials")

      assert_raises(Fs::AuthenticationError) do
        Fs::Api.new(FS_API_URL, handler: handler).fetch_forms
      end
    end

    test "raises authentication error for forbidden response" do
      handler = auth_error_handler(status: 403, body: "forbidden")

      assert_raises(Fs::AuthenticationError) do
        Fs::Api.new(FS_API_URL, handler: handler).fetch_forms
      end
    end

    test "does not treat non-auth server errors as authentication errors" do
      handler = auth_error_handler(status: 500, body: "server error")

      error = assert_raises(StandardError) do
        Fs::Api.new(FS_API_URL, handler: handler).fetch_forms
      end

      assert_not_instance_of Fs::AuthenticationError, error
    end

    test "maps raised unauthorized response to authentication error" do
      handler = raised_response_handler(status: 401, body: "bad credentials")

      assert_raises(Fs::AuthenticationError) do
        Fs::Api.new(FS_API_URL, handler: handler).fetch_forms
      end
    end

    test "maps raised non-auth response to standard error" do
      handler = raised_response_handler(status: 500, body: "server error")

      error = assert_raises(StandardError) do
        Fs::Api.new(FS_API_URL, handler: handler).fetch_forms
      end

      assert_not_instance_of Fs::AuthenticationError, error
    end

    test "pdf_visualization returns the pdf bytes" do
      handler = pdf_visualization_handler(status: 200, content_type: "application/pdf", body: "%PDF-1.7 fake")
      fs_api = Fs::Api.new(FS_API_URL, api_connection: api_connections(:fs_api_connection2), handler: handler)

      assert_equal "%PDF-1.7 fake", fs_api.pdf_visualization("123_456", "<dokument/>")
    end

    test "pdf_visualization returns nil on error response and logs why" do
      handler = pdf_visualization_handler(status: 422, content_type: "application/json", body: '{"result":"FAIL","message":"unsupported"}')
      fs_api = Fs::Api.new(FS_API_URL, api_connection: api_connections(:fs_api_connection2), handler: handler)
      warnings = []

      Rails.logger.stub(:warn, ->(message) { warnings << message }) do
        assert_nil fs_api.pdf_visualization("123_456", "<dokument/>")
      end

      assert_equal [ 'FS PDF visualization of 123_456 failed with 422: {"result":"FAIL","message":"unsupported"}' ], warnings
    end

    test "pdf_visualization in the background waits out Retry-After, or 30 s without it, and asks again while busy" do
      ingress_busy = OpenStruct.new(body: "<html>503</html>", status: 503, headers: { "content-type" => "text/html" })
      handler = pdf_visualization_responses(busy_response, ingress_busy, OpenStruct.new(body: "%PDF-1.7 fake", status: 200, headers: { "content-type" => "application/pdf" }))
      fs_api = Fs::Api.new(FS_API_URL, api_connection: api_connections(:fs_api_connection2), handler: handler)
      slept = []

      fs_api.stub(:sleep, ->(seconds) { slept << seconds }) do
        assert_equal "%PDF-1.7 fake", fs_api.pdf_visualization("123_456", "<dokument/>", in_background: true)
      end

      assert_equal [ Fs::Api::PDF_VISUALIZATION_TIMEOUT ] * 3, handler.timeouts
      assert_equal [ 30, 30 ], slept.map(&:round)
    end
    test "pdf_visualization in the background gives up when the FS API stays busy, without waiting after the last answer" do
      handler = pdf_visualization_responses(*Array.new(Fs::Api::PDF_VISUALIZATION_ATTEMPTS) { busy_response })
      fs_api = Fs::Api.new(FS_API_URL, api_connection: api_connections(:fs_api_connection2), handler: handler)
      slept = []

      fs_api.stub(:sleep, ->(seconds) { slept << seconds }) do
        assert_raises(Fs::PdfVisualizationUnavailable) { fs_api.pdf_visualization("123_456", "<dokument/>", in_background: true) }
      end
      assert_equal Fs::Api::PDF_VISUALIZATION_ATTEMPTS, handler.posts
      assert_equal Fs::Api::PDF_VISUALIZATION_ATTEMPTS - 1, slept.size
    end
    test "pdf_visualization does not ask again when the FS API rejects the form" do
      handler = pdf_visualization_responses(OpenStruct.new(body: '{"result":"FAIL"}', status: 500, headers: { "content-type" => "application/json" }))
      fs_api = Fs::Api.new(FS_API_URL, api_connection: api_connections(:fs_api_connection2), handler: handler)

      assert_nil fs_api.pdf_visualization("123_456", "<dokument/>", in_background: true)
      assert_equal 1, handler.posts
    end

    test "pdf_visualization for a person waiting on it asks once and gives up before the ingress does" do
      handler = pdf_visualization_responses(busy_response, busy_response)
      fs_api = Fs::Api.new(FS_API_URL, api_connection: api_connections(:fs_api_connection2), handler: handler)

      assert_raises(Fs::PdfVisualizationUnavailable) { fs_api.pdf_visualization("123_456", "<dokument/>") }
      assert_equal 1, handler.posts
      assert_equal [ Fs::Api::PDF_VISUALIZATION_INTERACTIVE_TIMEOUT ], handler.timeouts
      assert_operator Fs::Api::PDF_VISUALIZATION_INTERACTIVE_TIMEOUT, :<, 60, "nginx ingress answers 504 after its default 60 s"
    end

    test "pdf_visualization tells the FS API is unavailable and logs why when it does not answer in time" do
      handler = pdf_visualization_responses(Faraday::TimeoutError.new("timeout"))
      fs_api = Fs::Api.new(FS_API_URL, api_connection: api_connections(:fs_api_connection2), handler: handler)
      warnings = []

      Rails.logger.stub(:warn, ->(message) { warnings << message }) do
        assert_raises(Fs::PdfVisualizationUnavailable) { fs_api.pdf_visualization("123_456", "<dokument/>", in_background: true) }
      end

      assert_equal [ "FS PDF visualization of 123_456 failed with Faraday::TimeoutError: timeout" ], warnings
    end

    test "pdf_visualization tells a form too large to visualize apart, so nobody asks again" do
      too_large = OpenStruct.new(body: '{"result":"FAIL","message":"Form XML is too large to visualize as PDF: 596 kB"}', status: 413,
                                 headers: { "content-type" => "application/json" })
      handler = pdf_visualization_responses(too_large)
      fs_api = Fs::Api.new(FS_API_URL, api_connection: api_connections(:fs_api_connection2), handler: handler)

      assert_raises(Fs::PdfVisualizationTooLarge) { fs_api.pdf_visualization("123_456", "<dokument/>", in_background: true) }
      assert_equal 1, handler.posts
    end

    test "pdf_visualization returns nil when the response is not a pdf" do
      handler = pdf_visualization_handler(status: 200, content_type: "application/json", body: '{"result":"OK"}')
      fs_api = Fs::Api.new(FS_API_URL, api_connection: api_connections(:fs_api_connection2), handler: handler)

      assert_nil fs_api.pdf_visualization("123_456", "<dokument/>")
    end

    private

    def auth_error_handler(status:, body:)
      Class.new do
        class << self
          attr_accessor :response
        end

        self.response = OpenStruct.new(body: body, status: status, headers: "")

        def self.options
          @options ||= OpenStruct.new
        end

        def self.public_send(*)
          response
        end
      end
    end

    def raised_response_handler(status:, body:)
      Class.new do
        def self.options
          @options ||= OpenStruct.new
        end

        define_singleton_method(:public_send) do |*|
          error = StandardError.new("request failed")
          error.define_singleton_method(:response) { { status: status, body: body } }
          raise error
        end
      end
    end

    def pdf_visualization_handler(status:, content_type:, body:)
      Class.new do
        class << self
          attr_accessor :response
        end

        self.response = OpenStruct.new(body: body, status: status, headers: { "content-type" => content_type })

        def self.options
          @options ||= OpenStruct.new
        end

        def self.post(*)
          response
        end
      end
    end

    def pdf_visualization_responses(*responses)
      Class.new do
        class << self
          attr_accessor :responses, :posts, :timeouts
        end

        self.responses = responses
        self.posts = 0
        self.timeouts = []

        def self.post(*)
          self.posts += 1
          request = OpenStruct.new(options: OpenStruct.new)
          yield request
          timeouts << request.options.timeout

          response = responses.shift
          raise response if response.is_a?(Exception)

          response
        end
      end
    end

    def busy_response
      OpenStruct.new(body: '{"result":"FAIL","message":"Too many PDF visualizations in flight, try again later"}',
                     status: 503, headers: { "content-type" => "application/json", "retry-after" => "30" })
    end
  end
end
