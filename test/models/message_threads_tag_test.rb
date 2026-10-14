# frozen_string_literal: true

require "test_helper"

class MessageThreadsTagTest < ActiveSupport::TestCase
  # Fixtures used:
  #   ssd_main_general_legal      – thread: ssd_main_general, tag: ssd_legal (ordinary, visible)
  #   ssd_main_general_access_tag – thread: ssd_main_general, tag: ssd_access_tag
  #                                  (visible, tag_groups_count: 1, group: ssd_basic_user)
  #
  # Users:
  #   basic      – in ssd_basic_user (member of ssd_access_tag group)
  #   ssd_signer – in ssd_signer_user (NOT member of ssd_access_tag group)
  #   admin      – in ssd_admins (AdminGroup)

  setup do
    @thread = message_threads(:ssd_main_general)
  end

  # --- only_visible_tags_for ---

  test "only_visible_tags_for returns ordinary visible tag for member" do
    user = users(:basic)
    result = @thread.message_threads_tags.only_visible_tags_for(user)
    assert_includes result.map(&:tag), tags(:ssd_legal)
  end

  test "only_visible_tags_for returns access tag for member of its group" do
    user = users(:basic)
    result = @thread.message_threads_tags.only_visible_tags_for(user)
    assert_includes result.map(&:tag), tags(:ssd_access_tag)
  end

  test "only_visible_tags_for excludes access tag for non-member" do
    user = users(:ssd_signer)
    result = @thread.message_threads_tags.only_visible_tags_for(user)
    refute_includes result.map(&:tag), tags(:ssd_access_tag)
  end

  test "only_visible_tags_for includes ordinary tag for non-member" do
    user = users(:ssd_signer)
    result = @thread.message_threads_tags.only_visible_tags_for(user)
    assert_includes result.map(&:tag), tags(:ssd_legal)
  end

  test "only_visible_tags_for returns all visible tags for admin" do
    user = users(:admin)
    result = @thread.message_threads_tags.only_visible_tags_for(user)
    tag_list = result.map(&:tag)
    assert_includes tag_list, tags(:ssd_legal)
    assert_includes tag_list, tags(:ssd_access_tag)
  end

  test "only_visible_tags_for excludes hidden tags" do
    # ssd_main_general has ssd_main_general_external (visible: false)
    user = users(:admin)
    result = @thread.message_threads_tags.only_visible_tags_for(user)
    refute_includes result.map(&:tag), tags(:ssd_external)
  end
end
