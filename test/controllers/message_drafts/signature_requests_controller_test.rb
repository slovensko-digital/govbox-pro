require "test_helper"

class MessageDrafts::SignatureRequestsControllerTest < ActionController::TestCase
  setup do
    @tenant = tenants(:accountants)
    @user = users(:accountants_basic)
    @owner = users(:accountants_user2)
    @user.groups << @tenant.signer_group
    @owner.groups << @tenant.signer_group
    api_connections(:fs_api_connection1).update!(owner: @owner)

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

  test "edit offers only signers who can sign the Fs::MessageDraft" do
    get :edit, params: { message_draft_id: @message_draft.id, object_ids: [@message_draft.form_object.id] }

    assert_response :success
    assert_select "#new_assignments_#{groups(:accountants_user2_group).id}"
    assert_select "#new_assignments_#{groups(:accountants_basic_user).id}", count: 0
    assert_select "#new_assignments_#{groups(:accountants_signers).id}", count: 0
  end

  test "edit keeps already requested signer group so the request can be removed" do
    @tenant.signer_group.signature_requested_from_tag.assign_to_message_object(@message_draft.form_object)

    get :edit, params: { message_draft_id: @message_draft.id, object_ids: [@message_draft.form_object.id] }

    assert_response :success
    assert_select "#new_assignments_#{groups(:accountants_signers).id}"
  end
end
