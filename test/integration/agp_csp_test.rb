require "test_helper"

class AgpCspTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = tenants(:ssd)
    @user = users(:basic)
    @original_google_client_id = ENV["GOOGLE_CLIENT_ID"]
    ENV["GOOGLE_CLIENT_ID"] = "test"

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] =
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "123456789",
        info: { name: @user.name, email: @user.email },
        credentials: { token: "token", refresh_token: "refresh token" }
      )
  end

  teardown do
    ENV["GOOGLE_CLIENT_ID"] = @original_google_client_id
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  # the signing modal opens on pages loaded earlier, whose policy stays in force across Turbo visits
  test "every page of a tenant with autogram portal allows the AGP iframe and SDK" do
    @tenant.update!(
      feature_flags: (@tenant.feature_flags + ["autogram_portal"]).uniq,
      settings_agp_api_url: "https://agp.example.test:8443/",
      settings_agp_api_token_private_key: OpenSSL::PKey::RSA.generate(2048).to_pem,
      settings_agp_sub: "govbox-test"
    )

    post "/auth/google_oauth2"
    follow_redirect!
    get message_threads_path

    policy = response.headers.fetch("Content-Security-Policy")
    assert_match %r{frame-src 'self' https://agp\.example\.test:8443;}, policy
    assert_match %r{script-src 'self' https://agp\.example\.test:8443 'nonce-}, policy

    # the SDK delegates loopback access to the iframe for the calls to the local Autogram app, which works only
    # while the page itself keeps the permission
    assert_no_match(/local-network|loopback-network/, response.headers["Permissions-Policy"].to_s)
  end

  test "tenant without autogram portal does not allow AGP" do
    post "/auth/google_oauth2"
    follow_redirect!
    get message_threads_path

    policy = response.headers.fetch("Content-Security-Policy")
    assert_match %r{frame-src 'self';}, policy
  end
end
