require "test_helper"

class Fs::ApiConnectionCredentialsTest < ActiveSupport::TestCase
  test "authentication failure creates sticky notes for tenant admins" do
    api_connection = api_connections(:fs_api_connection1)
    admin = users(:accountants_basic)

    api_connection.mark_authentication_failed!

    sticky_note = admin.reload.sticky_note
    assert_equal "fs_authentication_failed", sticky_note.note_type
    assert_equal api_connection.id, sticky_note.data["api_connection_id"]
    assert_equal api_connection.name, sticky_note.data["api_connection_name"]
  end

  test "authentication failure is NOT cleared when credentials change" do
    api_connection = api_connections(:fs_api_connection1)
    api_connection.mark_authentication_failed!

    assert api_connection.authentication_failed?

    api_connection.update!(settings_password: "changed-password")

    assert api_connection.reload.authentication_failed?
  end

  test "authentication failure is cleared after successful clear_authentication_failure!" do
    api_connection = api_connections(:fs_api_connection1)
    admin = users(:accountants_basic)
    api_connection.mark_authentication_failed!

    assert api_connection.authentication_failed?
    assert_not_nil admin.reload.sticky_note

    api_connection.clear_authentication_failure!

    assert_not api_connection.reload.authentication_failed?
    assert_nil admin.reload.sticky_note
  end

  test "needs credentials setup when credentials are missing or authentication failed" do
    api_connection = api_connections(:fs_api_connection1)

    api_connection.update!(settings_username: nil, settings_password: "password")
    assert api_connection.needs_credentials_setup?

    api_connection.update!(settings_username: "username", settings_password: "password")
    assert_not api_connection.needs_credentials_setup?

    api_connection.mark_authentication_failed!
    assert api_connection.needs_credentials_setup?
  end
end
