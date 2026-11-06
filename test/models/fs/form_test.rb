# frozen_string_literal: true

require "test_helper"

class Fs::FormTest < ActiveSupport::TestCase
  test "#pdf_visualization returns nil without any request when the feature flag is disabled" do
    message_object = fs_message_object(pdf_supported: true, feature_enabled: false)

    FsEnvironment.fs_client.stub :api, ->(**) { flunk "should not call the FS API" } do
      assert_nil message_object.message.form.pdf_visualization(message_object)
    end
  end

  test "#pdf_visualization returns nil without any request when the form does not support pdf" do
    message_object = fs_message_object(pdf_supported: false, feature_enabled: true)

    FsEnvironment.fs_client.stub :api, ->(**) { flunk "should not call the FS API" } do
      assert_nil message_object.message.form.pdf_visualization(message_object)
    end
  end

  test "#pdf_visualization posts unsigned content and returns the pdf bytes" do
    message_object = fs_message_object(pdf_supported: true, feature_enabled: true)

    fs_api = Minitest::Mock.new
    fs_api.expect :pdf_visualization, "%PDF-bytes", [message_object.message.form.identifier, message_object.unsigned_content]

    fs_client = lambda do |api_connection:|
      assert_equal message_object.message.box.api_connection, api_connection
      fs_api
    end

    FsEnvironment.fs_client.stub :api, fs_client do
      assert_equal "%PDF-bytes", message_object.message.form.pdf_visualization(message_object)
    end

    fs_api.verify
  end

  test "#pdf_visualization lets fs client errors propagate" do
    message_object = fs_message_object(pdf_supported: true, feature_enabled: true)

    FsEnvironment.fs_client.stub :api, ->(**) { raise Faraday::ConnectionFailed, "connection reset" } do
      assert_raises(Faraday::ConnectionFailed) { message_object.message.form.pdf_visualization(message_object) }
    end
  end

  private

  def fs_message_object(pdf_supported:, feature_enabled:)
    message_object = message_objects(:fs_accountants_dphv21_form)
    message_object.message.form.update!(pdf_supported: pdf_supported)
    message_object.message.tenant.enable_feature(:fs_pdf_visualization, force: true) if feature_enabled

    message_object
  end
end
