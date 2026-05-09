require "test_helper"

class UsersApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
  end

  test "lists users for tenant" do
    tenant = tenants(:ssd)

    get "/api/users", params: { token: generate_api_token(sub: tenant.id, key_pair: @key_pair) }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal tenant.users.order(:id).pluck(:id), json_response.pluck("id")
    assert_equal ["Basic user", "Another user", "Signer user", "Signer user 2", "Admin user", "Notification user"].to_set, json_response.pluck("name").to_set
  end
end
