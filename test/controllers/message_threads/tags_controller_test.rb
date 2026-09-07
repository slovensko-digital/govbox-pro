# frozen_string_literal: true

require "test_helper"

class MessageThreads::TagsControllerTest < ActionController::TestCase
  tests MessageThreads::TagsController

  setup do
    @tenant  = tenants(:ssd)
    @thread  = message_threads(:ssd_main_general)

    sign_in_as(:basic)
  end

  teardown do
    Current.reset
  end

  # --- update (saving tag changes) ---

  test "update allows adding an ordinary tag for non-admin user" do
    tag = tags(:ssd_print)
    init_assignments = { tag.id.to_s => "-" }
    new_assignments  = { tag.id.to_s => "+" }

    assert_difference("MessageThreadsTag.count", 1) do
      patch :update, params: {
        message_thread_id: @thread.id,
        tags_assignments: { init: init_assignments, new: new_assignments }
      }
    end
    assert_redirected_to message_thread_path(@thread)
  end

  test "update allows adding access tag by member of its group" do
    # ssd_access_tag is already on the thread (fixture); remove it first, then re-add
    MessageThreadsTag.where(message_thread: @thread, tag: tags(:ssd_access_tag)).destroy_all

    tag = tags(:ssd_access_tag)
    init_assignments = { tag.id.to_s => "-" }
    new_assignments  = { tag.id.to_s => "+" }

    assert_difference("MessageThreadsTag.count", 1) do
      patch :update, params: {
        message_thread_id: @thread.id,
        tags_assignments: { init: init_assignments, new: new_assignments }
      }
    end
    assert_redirected_to message_thread_path(@thread)
  end

  test "update rejects adding access tag by non-member via crafted request" do
    sign_in_as(:ssd_signer)  # NOT in ssd_basic_user group

    # Simulate: signer sees legal tag in the form (it's an ordinary tag → visible to them),
    # then crafts the POST to also add the access tag they should not see.
    legal_tag  = tags(:ssd_legal)
    access_tag = tags(:ssd_access_tag)

    init_assignments = { legal_tag.id.to_s => "-" }
    new_assignments  = { legal_tag.id.to_s => "-", access_tag.id.to_s => "+" }

    assert_raises(ActiveRecord::RecordNotFound) do
      patch :update, params: {
        message_thread_id: @thread.id,
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
