# frozen_string_literal: true

require "test_helper"

class MessageThreadsTagPolicyTest < ActiveSupport::TestCase
  setup do
    @thread           = message_threads(:ssd_main_general)
    @ordinary_tag     = tags(:ssd_legal)              # no tag_groups → not an access tag
    @access_tag       = tags(:ssd_access_tag)          # tag_groups_count: 1, group: ssd_basic_user
    @member_user      = users(:basic)                  # in ssd_basic_user group
    @non_member_user  = users(:ssd_signer)             # in ssd_signer_user, NOT ssd_basic_user
    @admin_user       = users(:admin)                  # in ssd_admins (AdminGroup)

    @ordinary_mtt = MessageThreadsTag.new(message_thread: @thread, tag: @ordinary_tag)
    @access_mtt   = message_threads_tags(:ssd_main_general_access_tag)
  end

  # --- destroy? for ordinary tags (no access groups) ---

  test "destroy? is true for non-admin member on ordinary tag" do
    policy = MessageThreadsTagPolicy.new(@member_user, @ordinary_mtt)
    assert policy.destroy?
  end

  test "destroy? is true for non-admin non-member on ordinary tag" do
    policy = MessageThreadsTagPolicy.new(@non_member_user, @ordinary_mtt)
    assert policy.destroy?
  end

  test "destroy? is true for admin on ordinary tag" do
    policy = MessageThreadsTagPolicy.new(@admin_user, @ordinary_mtt)
    assert policy.destroy?
  end

  # --- destroy? for access tags (tag_groups_count > 0) ---

  test "destroy? is true for member of the access tag group" do
    policy = MessageThreadsTagPolicy.new(@member_user, @access_mtt)
    assert policy.destroy?
  end

  test "destroy? is false for non-member of the access tag group" do
    policy = MessageThreadsTagPolicy.new(@non_member_user, @access_mtt)
    refute policy.destroy?
  end

  test "destroy? is true for admin on access tag" do
    policy = MessageThreadsTagPolicy.new(@admin_user, @access_mtt)
    assert policy.destroy?
  end
end
