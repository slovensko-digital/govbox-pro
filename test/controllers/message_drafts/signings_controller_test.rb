require "test_helper"

class MessageDrafts::SigningsControllerTest < ActionController::TestCase
  setup do
    @tenant = tenants(:accountants)
    @user = users(:accountants_basic)
    @user.groups << @tenant.signer_group
    @message_draft = messages(:fs_accountants_draft_uzmujv14_with_attachment)

    Current.tenant = @tenant
    Current.user = @user
    session[:tenant_id] = @tenant.id
    session[:user_id] = @user.id
    session[:login_expires_at] = Time.current + 1.day
  end

  teardown do
    Current.reset
  end

  test "new starts signing for a signer allowed to sign the Fs::MessageDraft" do
    get :new, params: { message_draft_id: @message_draft.id, object_ids: [@message_draft.form_object.id] }

    assert_response :success
  end

  test "new denies signing for a signer who does not own the only api connection of the box" do
    api_connections(:fs_api_connection1).update!(owner: users(:accountants_user2))

    get :new, params: { message_draft_id: @message_draft.id, object_ids: [@message_draft.form_object.id] }

    assert_redirected_to root_path
    assert_equal "Prístup bol zamietnutý", flash[:alert]
  end
end
