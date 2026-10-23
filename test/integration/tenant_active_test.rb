require "test_helper"

class TenantActiveTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = tenants(:ssd)
    @user = users(:basic)
    @original_google_client_id = ENV["GOOGLE_CLIENT_ID"]
    ENV["GOOGLE_CLIENT_ID"] = "test"
  end

  teardown do
    ENV["GOOGLE_CLIENT_ID"] = @original_google_client_id
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "blocks login when tenant is inactive" do
    @tenant.update!(active_until: 1.hour.ago)

    mock_google_oauth(@user)

    post "/auth/google_oauth2"
    follow_redirect!

    assert_redirected_to auth_path
    assert_equal I18n.t("sessions.tenant_inactive"), flash[:alert]
    assert_nil session[:user_id]
    assert_nil session[:tenant_id]
  end

  test "terminates session when tenant becomes inactive mid-session" do
    mock_google_oauth(@user)

    post "/auth/google_oauth2"
    follow_redirect!

    assert_equal @user.id, session[:user_id]

    @tenant.update!(active_until: 1.hour.ago)

    get root_path

    assert_redirected_to auth_path
    assert_equal I18n.t("sessions.tenant_inactive"), flash[:alert]
    assert_nil session[:user_id]
    assert_nil session[:tenant_id]
  end

  private

  def mock_google_oauth(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] =
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "123456789",
        info: { name: user.name, email: user.email },
        credentials: { token: "token", refresh_token: "refresh token" }
      )
  end
end
