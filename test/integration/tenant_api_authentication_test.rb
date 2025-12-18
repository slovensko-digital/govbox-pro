require "test_helper"

class TenantApiAuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
  end

  test "accepts string sub in token" do
    get "/api/messages/sync", params: { token: generate_api_token(sub: @tenant.id.to_s, key_pair: @key_pair) }, as: :json

    assert_response :success
  end

  test "returns 401 unless tenant exists" do
    get "/api/messages/sync", params: { token: generate_api_token(sub: 123, key_pair: @key_pair) }, as: :json

    assert_response :unauthorized
  end

  test "returns 401 if api feature not enabled for tenant" do
    @tenant.feature_flags.delete("api")
    @tenant.save

    get "/api/messages/sync", params: { token: generate_api_token(sub: @tenant.id.to_s, key_pair: @key_pair) }, as: :json

    assert_response :unauthorized
  end

  test "returns 401 if signature verification failed" do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_invalid_cert.pem'

    get "/api/messages/sync", params: { token: generate_api_token(sub: @tenant.id.to_s, key_pair: @key_pair) }, as: :json

    assert_response :unauthorized
  end

  test "returns 401 if exp verification failed" do
    get "/api/messages/sync", params: { token: generate_api_token(sub: @tenant.id.to_s, key_pair: @key_pair, exp: (Time.now + 5.minutes + 2.seconds).to_i) }, as: :json

    assert_response :unauthorized
  end
end
