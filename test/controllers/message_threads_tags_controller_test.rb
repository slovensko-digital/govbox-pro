# frozen_string_literal: true

require "test_helper"

class MessageThreadsTagsControllerTest < ActionController::TestCase
  setup do
    @thread       = message_threads(:ssd_main_general)
    @ordinary_mtt = message_threads_tags(:ssd_main_general_legal)
    @access_mtt   = message_threads_tags(:ssd_main_general_access_tag)

    sign_in_as(:basic)
  end

  teardown do
    Current.reset
  end

  test "destroy succeeds for non-admin removing an ordinary tag" do
    assert_difference("MessageThreadsTag.count", -1) do
      delete :destroy, params: { id: @ordinary_mtt.id }
    end
    assert_redirected_to message_threads_path
  end

  test "destroy succeeds for member removing an access tag from the thread" do
    # basic user is in ssd_basic_user group which controls ssd_access_tag
    assert_difference("MessageThreadsTag.count", -1) do
      delete :destroy, params: { id: @access_mtt.id }
    end
    assert_redirected_to message_threads_path
  end

  test "destroy is denied for non-member trying to remove an access tag" do
    sign_in_as(:ssd_signer)  # NOT in ssd_basic_user group

    assert_no_difference("MessageThreadsTag.count") do
      delete :destroy, params: { id: @access_mtt.id }
    end
    assert_redirected_to root_path
    assert_equal "Prístup bol zamietnutý", flash[:alert]
  end

  test "destroy succeeds for admin removing any access tag" do
    sign_in_as(:admin)

    assert_difference("MessageThreadsTag.count", -1) do
      delete :destroy, params: { id: @access_mtt.id }
    end
    assert_redirected_to message_threads_path
  end

  private

  def sign_in_as(user_fixture)
    user = users(user_fixture)
    Current.user   = user
    Current.tenant = user.tenant
    session[:user_id]          = user.id
    session[:tenant_id]        = user.tenant_id
    session[:login_expires_at] = Time.current + 1.day
    session[:box_id]           = boxes(:ssd_main).id
  end
end
