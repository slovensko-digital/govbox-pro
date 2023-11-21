module AuthHelper
  def mock_auth_and_sign_in_as(user)
    mock_omni_auth_with_user(user)

    visit auth_path

    click_on "Prihlásiť cez Google"

    assert_text "Správy v schránke"
  end

  def mock_omni_auth_with_user(user)
    OmniAuth.config.test_mode = true

    OmniAuth.config.mock_auth[:google_oauth2] =
      OmniAuth::AuthHash.new(
        {
          provider: "google_oauth2",
          uid: "123456789",
          info: {
            name: user.name,
            email: user.email
          },
          credentials: {
            token: "token",
            refresh_token: "refresh token"
          }
        }
      )
  end

  def sign_out
    find("#user-menu-button").click
    click_on "Odhlásiť sa"

    assert_text "Prihláste sa"
  end
end
