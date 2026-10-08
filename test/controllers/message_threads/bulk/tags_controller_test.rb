require "test_helper"

module MessageThreads
  module Bulk
    class TagsControllerTest < ActionController::TestCase
      tests MessageThreads::Bulk::TagsController

      setup do
        @thread = message_threads(:ssd_main_general)
        @finance_tag = tags(:ssd_finance)
        @legal_tag = tags(:ssd_legal)
        # Fixtures insert tag_groups directly, bypassing the counter cache.
        Tag.reset_counters(@finance_tag.id, :tag_groups)
      end

      test "regular user cannot remove an access tag in bulk" do
        sign_in(users(:basic))
        assert_includes @thread.tags, @finance_tag

        patch :update, params: assignment_params(@thread, @finance_tag, from: "+", to: "-")

        @thread.reload
        assert_includes @thread.tags, @finance_tag
      end

      test "regular user can remove a classification tag in bulk" do
        sign_in(users(:basic))
        assert_includes @thread.tags, @legal_tag

        patch :update, params: assignment_params(@thread, @legal_tag, from: "+", to: "-")

        @thread.reload
        refute_includes @thread.tags, @legal_tag
      end

      test "user whose group has the permission can remove an access tag in bulk" do
        groups(:ssd_basic_user).update!(can_manage_access_tags: true)
        sign_in(users(:basic))

        patch :update, params: assignment_params(@thread, @finance_tag, from: "+", to: "-")

        @thread.reload
        refute_includes @thread.tags, @finance_tag
      end

      test "edit renders an access tag as disabled for a regular user" do
        sign_in(users(:basic))

        post :edit, params: { message_thread_ids: [@thread.id] }

        assert_response :success
        assert_select "input[type=checkbox][id=?][disabled]", "new_tags_assignments_#{@finance_tag.id}", count: 1
        assert_select "input[type=hidden][name=?]", "tags_assignments[new][#{@finance_tag.id}]", count: 0
      end

      private

      def sign_in(user)
        Current.user = user
        session[:login_expires_at] = Time.now + 1.day
        session[:user_id] = user.id
        session[:tenant_id] = user.tenant_id
        session[:box_id] = boxes(:ssd_main).id
      end

      def assignment_params(thread, tag, from:, to:)
        {
          message_thread_ids: [thread.id],
          tags_assignments: {
            init: { tag.id.to_s => from },
            new: { tag.id.to_s => to }
          }
        }
      end
    end
  end
end
