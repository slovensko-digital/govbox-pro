require "test_helper"

class ApiConnectionsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:accountants)
  end

  test "index returns api connections without sensitive fields" do
    get "/api/api_connections", params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = response.parsed_body

    assert json_response.is_a?(Array)

    connection = api_connections(:fs_api_connection1)
    connection_json = json_response.find { |it| it["id"] == connection.id }

    assert connection_json.present?
    assert_equal connection.type, connection_json["type"]
    assert_equal connection.sub, connection_json["sub"]
    assert_not connection_json.key?("settings")
    assert_not connection_json.key?("api_token_private_key")
  end

  test "boxify executes for FS api connection" do
    connection = api_connections(:fs_api_connection1)

    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, []

    FsEnvironment.fs_client.stub :api, fs_api do
      post "/api/api_connections/#{connection.id}/boxify",
           params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) },
           as: :json
    end

    assert_response :success
    json_response = response.parsed_body

    assert_equal connection.id, json_response["id"]
    assert_equal 0, json_response["new_boxes_count"]
    assert_not json_response.key?("message")
  end

  test "boxify fails for non-FS api connection" do
    non_fs = Govbox::ApiConnectionWithOboSupport.create!(
      sub: "sub-test",
      api_token_private_key: "private_key",
      tenant: @tenant
    )

    post "/api/api_connections/#{non_fs.id}/boxify",
         params: { token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) },
         as: :json

    assert_response :unprocessable_content

    json_response = response.parsed_body
    assert_equal "Only FS API connections support the boxify action", json_response["message"]
  end
end
