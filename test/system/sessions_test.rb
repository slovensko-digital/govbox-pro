require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  test "login" do
    visit root_path

    assert_current_path auth_path

    assert_text "Prihláste sa"

    sign_in_as(:basic)
  end

  test "logout" do
    sign_in_as(:basic)

    sign_out
  end
end
