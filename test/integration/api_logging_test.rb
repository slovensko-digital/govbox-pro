require "test_helper"

class ApiLoggingTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
  end

  test "can log successful call" do
    thread = message_threads(:ssd_main_general)
    token =  generate_api_token(sub: @tenant.id, key_pair: @key_pair)
    get "/api/threads/#{thread.id}", params: { token: token }, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    api_request = ApiRequest.last
    assert api_request
    assert_equal api_request.type, "ApiRequest::ProvidedApiRequest"
    assert_match api_request.endpoint_path, request.url
    assert_equal api_request.endpoint_method, request.method
    assert_equal api_request.response_status, response.code.to_i
    assert_equal api_request.authenticity_token, token
  end

  test "can log errored call" do
    thread_id = 1
    thread_id += 1 while MessageThread.exists?(thread_id)
    token = generate_api_token(sub: @tenant.id, key_pair: @key_pair)
    get "/api/threads/#{thread_id}", params: { token: token }, as: :json
    assert_response :not_found
    api_request = ApiRequest.last
    assert api_request
    assert_equal api_request.type, "ApiRequest::ProvidedApiRequest"
    assert_match api_request.endpoint_path, request.url
    assert_equal api_request.endpoint_method, request.method
    assert_equal api_request.response_status, response.code.to_i
    assert_equal api_request.authenticity_token, token
  end
end
