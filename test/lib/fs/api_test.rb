# frozen_string_literal: true

require 'test_helper'

module Fs
  class ApiTest < ActiveSupport::TestCase
    FS_API_URL = ENV.fetch('FS_API_URL')

    test "box with delegate_id should create Fs::Api object that uses delegate_id in obo in fetch_sent_messages" do
      options = Minitest::Mock.new
      options.expect :timeout=, nil, [900_000]

      handler = Minitest::Mock.new
      handler.expect :options, options
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
    end

    test "box without delegate_id should create Fs::Api object that uses valid obo in fetch_sent_messages" do
      options = Minitest::Mock.new
      options.expect :timeout=, nil, [900_000]

      handler = Minitest::Mock.new
      handler.expect :options, options
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
  end
end
