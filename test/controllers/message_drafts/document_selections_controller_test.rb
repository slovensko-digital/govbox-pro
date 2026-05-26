require "test_helper"

module MessageDrafts
  class DocumentSelectionsControllerTest < ActionController::TestCase
    tests MessageDrafts::DocumentSelectionsController

    setup do
      @user = users(:ssd_signer)
      @message_draft = messages(:ssd_main_general_draft_one)

      Current.user = @user
      Current.tenant = @user.tenant
      session[:login_expires_at] = Time.current + 1.day
      session[:user_id] = @user.id
      session[:tenant_id] = @user.tenant_id
    end

    teardown do
      Current.reset
    end

    test "sign agp action submits selected objects to agp bundle setup with get" do
      get :new, params: { message_draft_id: @message_draft.id, next_step: "sign-agp" }

      assert_response :success
      assert_select "input[type='submit'][value='Pokračovať'][formmethod='get'][formaction='#{new_agp_bundle_path}']"
      assert_select "input[type='submit'][value='Pokračovať'][formaction*='object_ids']", count: 0
      assert_select "input[type='checkbox'][name='object_ids[]']", count: 2
    end
  end
end