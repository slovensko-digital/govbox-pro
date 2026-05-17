require "test_helper"

class SiteAdminFsOnboardingsTest < ActionDispatch::IntegrationTest
  test "creates onboarding" do
    onboarding_params = {
      tenant_name: "Test tenant",
      admin_user_name: "Test admin",
      saml_identifier: "test-saml-identifier",
      admin_user_contact_email: "admin@test.sk",
      fs_api_sub: "fs-api-sub",
      fs_api_private_key: "fs-api-private-key"
    }

    service = Minitest::Mock.new
    service.expect(:valid?, true)
    service.expect(:call, nil)

    Fs::OnboardTenant.stub(:new, ->(params) do
      assert_equal onboarding_params, params.to_h.symbolize_keys
      service
    end) do
      post "/api/site_admin/fs/onboardings",
           params: { onboarding: onboarding_params, token: generate_api_token },
           as: :json
    end

    assert_response :created
    assert_empty response.body
  end

  test "returns unauthorized for invalid token" do
    invalid_key_pair = OpenSSL::PKey::RSA.new(512)

    Fs::OnboardTenant.stub(:new, ->(_) { flunk "service should not be called for unauthorized requests" }) do
      post "/api/site_admin/fs/onboardings",
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
    post "/api/site_admin/fs/onboardings",
         params: { token: generate_api_token },
         as: :json

    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert_match "can't be blank", json_response["message"]
  end
end

