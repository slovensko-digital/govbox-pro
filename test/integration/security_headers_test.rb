require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  SECURITY_HEADERS = %w[
    content-security-policy
    permissions-policy
    referrer-policy
    x-content-type-options
    x-frame-options
    x-permitted-cross-domain-policies
  ].freeze

  setup do
    Rails.application.env_config["action_dispatch.show_exceptions"] = :all
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false
  end

  teardown do
    Rails.application.env_config.delete("action_dispatch.show_exceptions")
    Rails.application.env_config.delete("action_dispatch.show_detailed_exceptions")
  end

  test "sends security headers on a 404 error page" do
    get "/nonexistent_path"

    assert_response :not_found
    assert_security_headers
  end

  test "sends security headers on a 500 error page" do
    UpvsEnvironment.stub(:sso_support?, ->(*) { raise "boom" }) do
      get "/prihlasenie"
    end

    assert_response :internal_server_error
    assert_security_headers
  end

  test "sends security headers on a successful response" do
    get "/prihlasenie"

    assert_response :success
    assert_security_headers
  end

  private

  def assert_security_headers
    SECURITY_HEADERS.each do |header|
      assert response.headers[header].present?, "chyba hlavicka #{header} pri #{response.status}"
    end

    assert_includes response.headers["content-security-policy"], "default-src 'self'"
    assert_equal "SAMEORIGIN", response.headers["x-frame-options"]
  end
end
