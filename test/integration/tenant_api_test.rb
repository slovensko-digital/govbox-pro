require "test_helper"

class TenantApiTest < ActionDispatch::IntegrationTest
  test "can create tenant" do
    post "/api/site_admin/tenants", params: { tenant: { name: "Testovaci tenant",
                                                        feature_flags: [:audit_logs],
                                                        admin: { name: "Testovaci admin", email: "test@test.sk" } },
                                              token: generate_api_token },
                                    as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["id"]
    assert Tenant.exists?(json_response["id"])
    tenant = Tenant.find(json_response["id"])
    assert_empty tenant.feature_flags
    assert_equal "Testovaci tenant", tenant.name
    assert_equal "Testovaci admin", tenant.admin_group.users.first.name
    assert_equal "test@test.sk", tenant.admin_group.users.first.email
  end

  test "can not create tenant without admin" do
    post "/api/site_admin/tenants", params: { tenant: { name: "Testovaci tenant",
                                                        feature_flags: [:audit_logs] },
                                              token: generate_api_token },
                                    as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_match "param is missing or the value is empty: admin", json_response["message"]
  end

  test "can destroy tenant" do
    tenant = tenants(:solver)
    tenant_id = tenant.id

    delete "/api/site_admin/tenants/#{tenant.id}", params: { token: generate_api_token }, as: :json

    assert_response :no_content
    assert_not Tenant.exists?(tenant_id)
  end

  test "can add box with obo" do
    tenant = tenants(:google)

    post "/api/site_admin/tenants/#{tenant.id}/boxes",
         params: { box: { name: "Test box",
                          uri: "ico://sk//12345678",
                          short_name: "TST",
                          color: "blue",
                          api_connection_id: api_connections(:govbox_api_api_connection_with_obo_support).id,
                          settings_obo: SecureRandom.uuid },
                   token: generate_api_token },
         as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    box = tenant.boxes.find_by(name: "Test box")
    assert box
    assert json_response["id"]
    assert_equal box.id, json_response["id"]
  end

  test "can add box with new api connection without obo" do
    tenant = tenants(:solver)

    post "/api/site_admin/tenants/#{tenant.id}/boxes",
         params: { box: { name: "Test box",
                          uri: "ico://sk//12345678",
                          short_name: "TST",
                          color: "blue",
                          api_connection: { sub: "sub", api_token_private_key: "supertajnykluc" } },
                   token: generate_api_token },
         as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    box = tenant.boxes.find_by(name: "Test box")
    assert box
    assert json_response["id"]
    assert_equal box.id, json_response["id"]
    assert_equal "supertajnykluc", box.api_connection.api_token_private_key
  end

  test "can not add box without api connection" do
    tenant = tenants(:solver)

    post "/api/site_admin/tenants/#{tenant.id}/boxes",
         params: { box: { name: "Test box",
                          uri: "ico://sk//12345678",
                          short_name: "TST",
                          color: "blue" },
                   token: generate_api_token },
         as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "Api connection must be provided", json_response["message"]
    assert_not tenant.boxes.find_by(name: "Test box")
  end

  test "can not add box without tenant" do
    tenant = tenants(:solver)

    post "/api/site_admin/tenants//boxes",
         params: { box: { name: "Test box",
                          uri: "ico://sk//12345678",
                          short_name: "TST",
                          color: "blue" },
                   token: generate_api_token },
         as: :json

    assert_response :not_found
  end
end
