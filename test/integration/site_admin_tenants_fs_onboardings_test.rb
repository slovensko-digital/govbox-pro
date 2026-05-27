require "test_helper"

class SiteAdminTenantsFsOnboardingsTest < ActionDispatch::IntegrationTest
  test "creates onboarding" do
    onboarding_params = {
      tenant_name: "Test tenant",
      ico: "09173804",
      admin_user_name: "Test admin",
      saml_identifier: "test-saml-identifier",
      admin_user_contact_email: "admin@test.sk"
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :create_user, {
      "id" => 1
    },
    **{crm_identifier: onboarding_params[:tenant_name], api_token_public_key: String}

    FsEnvironment.fs_client.stub :admin_api, fs_api do
      post "/api/site_admin/tenants/fs/onboardings",
           params: { onboarding: onboarding_params, token: generate_api_token },
           as: :json
    end

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert json_response["id"].present?
  end

  test "returns unauthorized for invalid token" do
    invalid_key_pair = OpenSSL::PKey::RSA.new(512)

    Fs::OnboardingService.stub(:new, ->(_) { flunk "service should not be called for unauthorized requests" }) do
      post "/api/site_admin/tenants/fs/onboardings",
           params: {
             onboarding: {
               tenant_name: "Test tenant",
               admin_user_name: "Test admin",
               saml_identifier: "test-saml-identifier",
               fs_api_sub: "fs-api-sub",
               fs_api_private_key: "fs-api-private-key"
             },
             token: generate_api_token(key_pair: invalid_key_pair)
           },
           as: :json
    end

    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_match "Unauthorized", json_response["message"]
  end

  test "returns bad request when onboarding params are missing" do
    post "/api/site_admin/tenants/fs/onboardings",
         params: { token: generate_api_token },
         as: :json

    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert_match "can't be blank", json_response["message"]
  end

  test "returns conflict when creating the same tenant twice" do
    onboarding_params = {
      tenant_name: "Duplicate tenant",
      ico: "87654321",
      admin_user_name: "Admin",
      saml_identifier: "admin-dup@example.com",
      admin_user_contact_email: "admin-dup@example.com",
      fs_api_sub: "fs-api-sub",
      fs_api_private_key: "fs-api-private-key"
    }

    fs_api = Minitest::Mock.new
    fs_api.expect :create_user, {
      "id" => 1
    },
    **{crm_identifier: onboarding_params[:tenant_name], api_token_public_key: String}

    FsEnvironment.fs_client.stub :admin_api, fs_api do
      post "/api/site_admin/tenants/fs/onboardings",
           params: { onboarding: onboarding_params, token: generate_api_token },
           as: :json
    end

    assert_response :ok

    post "/api/site_admin/tenants/fs/onboardings",
         params: { onboarding: onboarding_params, token: generate_api_token },
         as: :json

    assert_response :conflict
    json_response = JSON.parse(response.body)
    assert_match "already exists", json_response["message"].downcase
  end
end

