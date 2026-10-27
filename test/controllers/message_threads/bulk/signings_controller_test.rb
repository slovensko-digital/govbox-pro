require 'test_helper'

module MessageThreads
  module Bulk
    class SigningsControllerTest < ActionController::TestCase
      tests MessageThreads::Bulk::SigningsController

      setup do
        @tenant = tenants(:accountants)
        @user = users(:accountants_basic)
        @user.groups << @tenant.signer_group

        @thread = message_threads(:fs_accountants_draft_uzmujv14_with_attachment)
        form_object = messages(:fs_accountants_draft_uzmujv14_with_attachment).form_object
        @tenant.signer_group.signature_requested_from_tag.assign_to_message_object(form_object)
        @tenant.signer_group.signature_requested_from_tag.assign_to_thread(@thread)

        Current.tenant = @tenant
        Current.user = @user
        session[:tenant_id] = @tenant.id
        session[:user_id] = @user.id
        session[:login_expires_at] = Time.current + 1.day
      end

      teardown do
        Current.reset
      end

      test 'new offers Fs::MessageDraft form object to the owner of the only api connection of the box' do
        api_connections(:fs_api_connection1).update!(owner: @user)

        post :new, params: { message_thread_ids: [@thread.id] }

        assert_response :success
      end

      test 'new skips Fs::MessageDraft form object if the only api connection of the box is owned by another user' do
        api_connections(:fs_api_connection1).update!(owner: users(:accountants_user2))

        post :new, params: { message_thread_ids: [@thread.id] }

        assert_redirected_to message_threads_path
        assert_equal "Vo vybraných vláknach sa nenašli žiadne dokumenty so žiadosťou na podpis", flash[:alert]
      end
    end
  end
end
