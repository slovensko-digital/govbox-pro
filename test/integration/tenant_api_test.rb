require "test_helper"

class TenantApiTest < ActionDispatch::IntegrationTest
  test "can create tenant" do
    post "/api/admin/tenants", params: { tenant: { name: "Testovaci tenant" } }, as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Testovaci tenant", json_response["name"]
    assert_not_nil json_response["id"]
    assert_empty json_response["feature_flags"]
  end

  test "can destroy tenant" do
    tenant = tenants(:solver)
    delete "/api/admin/tenants/#{tenant.id}", params: {}, as: :json
    assert_response :ok
    json_response = JSON.parse(response.body)
  end
end
