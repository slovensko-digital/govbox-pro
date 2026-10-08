# frozen_string_literal: true

require "test_helper"

module MessageThreads
  module Bulk
    class TagsControllerTest < ActionController::TestCase
      tests MessageThreads::Bulk::TagsController

      setup do
        @tenant  = tenants(:ssd)
        @thread  = message_threads(:ssd_main_general)
        @thread2 = message_threads(:ssd_main_issue)

        sign_in_as(:basic)
      end

      teardown do
        Current.reset
      end

      # --- update (bulk saving tag changes) ---

      test "update allows adding an ordinary tag in bulk for non-admin" do
        tag = tags(:ssd_print)
        init_assignments = { tag.id.to_s => "-" }
        new_assignments  = { tag.id.to_s => "+" }

        assert_difference("MessageThreadsTag.count", 2) do
          patch :update, params: {
            message_thread_ids: [@thread.id, @thread2.id],
            tags_assignments: { init: init_assignments, new: new_assignments }
          }
        end
      end

      test "update allows bulk-adding access tag by member of its group" do
        # Remove any existing access_tag assignment to start clean
        MessageThreadsTag.where(tag: tags(:ssd_access_tag)).destroy_all

        tag = tags(:ssd_access_tag)
        init_assignments = { tag.id.to_s => "-" }
        new_assignments  = { tag.id.to_s => "+" }

        assert_difference("MessageThreadsTag.count", 2) do
          patch :update, params: {
            message_thread_ids: [@thread.id, @thread2.id],
            tags_assignments: { init: init_assignments, new: new_assignments }
          }
        end
      end

      test "update rejects bulk-adding access tag by non-member via crafted request" do
        sign_in_as(:ssd_signer)

        # Simulate crafted request: signer includes an ordinary tag in init
        # (they can see it), but tries to sneak in the access tag in new.
        legal_tag  = tags(:ssd_legal)
        access_tag = tags(:ssd_access_tag)

        init_assignments = { legal_tag.id.to_s => "-" }
        new_assignments  = { legal_tag.id.to_s => "-", access_tag.id.to_s => "+" }

        assert_raises(ActiveRecord::RecordNotFound) do
          patch :update, params: {
            message_thread_ids: [@thread.id, @thread2.id],
            tags_assignments: { init: init_assignments, new: new_assignments }
          }
        end
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
  end
end
