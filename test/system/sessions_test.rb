require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  test "login" do
    visit root_path

    assert_current_path auth_path

    assert_text "Prihláste sa"

    mock_auth_and_sign_in_as(users(:basic))
  end

  test "logout" do
    mock_auth_and_sign_in_as(users(:basic))

    sign_out
  end
end
