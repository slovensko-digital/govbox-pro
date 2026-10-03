require "test_helper"

class NoAccountTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.mock_auth[:microsoft_graph] = nil
  end

  test "offers to retry with another Google account when Google login has no account" do
    mock_oauth(:google_oauth2, "unknown@example.com")

    post "/auth/google_oauth2"
    follow_redirect!

    assert_redirected_to no_account_sessions_path
    follow_redirect!

    assert_select "form[action='/auth/google_oauth2'] input[name='prompt'][value='select_account']"
    assert_select "button", text: "Skúsiť iný Google účet"
  end

  test "offers to retry with another Microsoft account when Microsoft login has no account" do
    mock_oauth(:microsoft_graph, "unknown@example.com")

    post "/auth/microsoft_graph"
    follow_redirect!

    assert_redirected_to no_account_sessions_path
    follow_redirect!

    assert_select "form[action='/auth/microsoft_graph'] input[name='prompt'][value='select_account']"
    assert_select "button", text: "Skúsiť iný Microsoft účet"
  end

  test "does not offer retry when there was no login" do
    get no_account_sessions_path

    assert_select "input[name='prompt']", count: 0
  end

  private

  def mock_oauth(provider, email)
    OmniAuth.config.mock_auth[provider] =
      OmniAuth::AuthHash.new(
        provider: provider.to_s,
        uid: "123456789",
        info: { name: "Unknown", email: email },
        credentials: { token: "token", refresh_token: "refresh token" }
      )
  end
end
