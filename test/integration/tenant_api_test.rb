require "test_helper"

class TenantApiTest < ActionDispatch::IntegrationTest
  test "can create tenant" do
    post "/api/admin/tenants", params: { tenant: { name: "Testovaci tenant" }, admin: { name: "Testovaci admin", email: "test@test.sk" } }, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Testovaci tenant", json_response["name"]
    assert_not_nil json_response["id"]
    assert_empty json_response["feature_flags"]
    assert Tenant.exists?(json_response["id"])
    assert Tenant.find(json_response["id"]).admin_group.users.first.name, "Testovaci admin"
    assert Tenant.find(json_response["id"]).admin_group.users.first.email, "test@test.sk"
  end

  test "can destroy tenant" do
    tenant = tenants(:solver)
    tenant_id = tenant.id
    delete "/api/admin/tenants/#{tenant.id}", params: {}, as: :json
    assert_response :no_content
    assert_not Tenant.exists?(tenant_id)
  end

  test "can add box" do
    tenant = tenants(:solver)
    post "/api/admin/tenants/#{tenant.id}/boxes", params: { box: { name: "Test box", uri: "ico://sk//12345678", short_name: "TST", color: "blue", api_connection_id: api_connections(:govbox_api_api_connection1).id } }, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Test box", json_response["name"]
  end
end
