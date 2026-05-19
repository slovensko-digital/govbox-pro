require "test_helper"

class AuthenticationRedirectTest < ActionDispatch::IntegrationTest

  test "stores navigational path while redirecting to login" do
    message = messages(:ssd_main_general_one)

    get message_path(message)

    assert_redirected_to auth_path
    assert_equal message_path(message), session[:after_login_path]
  end

  test "does not store export path while redirecting to login" do
    message = messages(:ssd_main_general_one)

    get export_message_path(message)

    assert_redirected_to auth_path
    assert_nil session[:after_login_path]
  end

  test "does not store attachment preview path while redirecting to login" do
    message = messages(:ssd_main_general_one)
    attachment = message_objects(:ssd_main_general_one_attachment)

    get message_message_object_path(message, attachment)

    assert_redirected_to auth_path
    assert_nil session[:after_login_path]
  end
end