# frozen_string_literal: true

require "test_helper"

class TagPolicyTest < ActiveSupport::TestCase
  # Fixtures:
  #   ssd_legal       – SimpleTag, visible: true,  tag_groups_count: 0  (ordinary)
  #   ssd_access_tag  – SimpleTag, visible: true,  tag_groups_count: 1, group: ssd_basic_user
  #   ssd_archived    – ArchivedTag, visible: true, tag_groups_count: 0
  #   ssd_hidden      – SimpleTag, visible: false, tag_groups_count: 0
  #
  # Users:
  #   basic      – in ssd_basic_user (member of ssd_access_tag group)
  #   ssd_signer – in ssd_signer_user (NOT member of ssd_access_tag group)
  #   admin      – in ssd_admins (AdminGroup)

  setup do
    @tenant        = tenants(:ssd)
    @member_user   = users(:basic)
    @non_member    = users(:ssd_signer)
    @admin_user    = users(:admin)

    Current.tenant = @tenant
  end

  teardown do
    Current.reset
  end

  # --- ScopeListable ---

  test "ScopeListable includes ordinary visible tags for non-admin member" do
    scope = TagPolicy::ScopeListable.new(@member_user, Tag).resolve
    assert_includes scope, tags(:ssd_legal)
  end

  test "ScopeListable includes access-controlled tag for member of its group" do
    scope = TagPolicy::ScopeListable.new(@member_user, Tag).resolve
    assert_includes scope, tags(:ssd_access_tag)
  end

  test "ScopeListable excludes access-controlled tag for non-member" do
    scope = TagPolicy::ScopeListable.new(@non_member, Tag).resolve
    refute_includes scope, tags(:ssd_access_tag)
  end

  test "ScopeListable excludes hidden tags for non-admin" do
    scope = TagPolicy::ScopeListable.new(@member_user, Tag).resolve
    refute_includes scope, tags(:ssd_hidden)
  end

  test "ScopeListable includes all visible tags for admin" do
    scope = TagPolicy::ScopeListable.new(@admin_user, Tag).resolve
    assert_includes scope, tags(:ssd_access_tag)
    assert_includes scope, tags(:ssd_legal)
    assert_includes scope, tags(:ssd_archived)
  end

  test "ScopeListable excludes hidden tags even for admin" do
    scope = TagPolicy::ScopeListable.new(@admin_user, Tag).resolve
    refute_includes scope, tags(:ssd_hidden)
  end

  test "ScopeListable includes non-simple visible tag with no access groups for non-admin" do
    scope = TagPolicy::ScopeListable.new(@member_user, Tag).resolve
    # ArchivedTag is visible and has no access groups → non-admin should see it
    assert_includes scope, tags(:ssd_archived)
  end
end
