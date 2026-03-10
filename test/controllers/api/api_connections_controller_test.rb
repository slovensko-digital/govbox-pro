require 'test_helper'

class Api::ApiConnectionsControllerTest < ActionDispatch::IntegrationTest
  test "index returns api connections" do
    tenant = tenants(:accountants)
    tenant.enable_feature(:api, force: true) unless tenant.feature_enabled?(:api)

    key_pair = OpenSSL::PKey::RSA.new(512)
    tenant.update!(api_token_public_key: key_pair.public_key)

    get api_api_connections_path,
        as: :json,
        headers: auth_header(generate_api_token(sub: tenant.id, key_pair: key_pair))

    assert_response :success

    assert response.parsed_body.is_a?(Array)

    connection = response.parsed_body.find { |it| it["id"] == api_connections(:fs_api_connection1).id }
    assert connection.present?

    assert_not connection.key?("settings")
    assert_not connection.key?("api_token_private_key")
  end

  test "boxify executes for FS api connection" do
    tenant = tenants(:accountants)
    tenant.enable_feature(:api, force: true) unless tenant.feature_enabled?(:api)

    key_pair = OpenSSL::PKey::RSA.new(512)
    tenant.update!(api_token_public_key: key_pair.public_key)

    connection = api_connections(:fs_api_connection1)

    fs_api = Minitest::Mock.new
    fs_api.expect :get_subjects, []

    FsEnvironment.fs_client.stub :api, fs_api do
      post boxify_api_api_connection_path(connection),
           as: :json,
           headers: auth_header(generate_api_token(sub: tenant.id, key_pair: key_pair))
    end

    assert_response :success
    assert_equal connection.id, response.parsed_body["id"]
    assert_equal 0, response.parsed_body["new_boxes_count"]
  end

  test "boxify fails for non-FS api connection" do
    tenant = tenants(:accountants)
    tenant.enable_feature(:api, force: true) unless tenant.feature_enabled?(:api)

    non_fs = Govbox::ApiConnectionWithOboSupport.create!(
      sub: "sub-test",
      api_token_private_key: "private_key",
      tenant: tenant
    )

    key_pair = OpenSSL::PKey::RSA.new(512)
    tenant.update!(api_token_public_key: key_pair.public_key)

    post boxify_api_api_connection_path(non_fs),
         as: :json,
         headers: auth_header(generate_api_token(sub: tenant.id, key_pair: key_pair))

    assert_response :unprocessable_content
    assert_equal "Only FS API connections support the boxify action", response.parsed_body["message"]
  end

  private

  def auth_header(token)
    { "Authorization" => "Bearer #{token}" }
  end
end
