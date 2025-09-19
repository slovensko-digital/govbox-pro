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
  end
end
