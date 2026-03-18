require "test_helper"
require "ostruct"

class MessagesAuthenticationRedirectTest < ActionController::TestCase
  tests MessagesController

  setup do
    session[:login_expires_at] = 1.day.ago
  end

  test "stores navigational path while redirecting to login" do
    message = messages(:ssd_main_general_one)

    get :show, params: { id: message.id }

    assert_redirected_to auth_path
    assert_equal message_path(message), session[:after_login_path]
  end

  test "does not store export path while redirecting to login" do
    message = messages(:ssd_main_general_one)

    get :export, params: { id: message.id }

    assert_redirected_to auth_path
    assert_nil session[:after_login_path]
  end
end

class MessageObjectsAuthenticationRedirectTest < ActionController::TestCase
  tests MessageObjectsController

  setup do
    session[:login_expires_at] = 1.day.ago
  end

  test "does not store attachment preview path while redirecting to login" do
    message = messages(:ssd_main_general_one)
    attachment = message_objects(:ssd_main_general_one_attachment)

    get :show, params: { message_id: message.id, id: attachment.id }

    assert_redirected_to auth_path
    assert_nil session[:after_login_path]
  end
end
