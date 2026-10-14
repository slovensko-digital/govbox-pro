require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "before_save callback normalizes saml_identifier attribute" do
    user = User.find_or_create_by(tenant: Tenant.first, name: 'New user', email: 'new_user@slovensko.digital', saml_identifier: '')

    assert_nil user.saml_identifier
  end

  # --- listable_tags ---

  test "listable_tags includes ordinary visible tags for non-admin" do
    user   = users(:basic)
    tenant = tenants(:ssd)
    # ssd_legal has tag_groups_count = 0 (ordinary) and visible = true
    assert_includes user.listable_tags(tenant), tags(:ssd_legal)
  end

  test "listable_tags includes access-controlled tag for member of its group" do
    user   = users(:basic)
    tenant = tenants(:ssd)
    # ssd_access_tag has tag_groups_count = 1, group = ssd_basic_user; basic is in that group
    assert_includes user.listable_tags(tenant), tags(:ssd_access_tag)
  end

  test "listable_tags excludes access-controlled tag for non-member" do
    user   = users(:ssd_signer)
    tenant = tenants(:ssd)
    # ssd_signer is in ssd_signer_user, NOT ssd_basic_user
    refute_includes user.listable_tags(tenant), tags(:ssd_access_tag)
  end

  test "listable_tags excludes hidden tags for non-admin" do
    user   = users(:basic)
    tenant = tenants(:ssd)
    refute_includes user.listable_tags(tenant), tags(:ssd_hidden)
  end

  test "listable_tags includes all visible tags for admin" do
    user   = users(:admin)
    tenant = tenants(:ssd)
    result = user.listable_tags(tenant)
    assert_includes result, tags(:ssd_access_tag)
    assert_includes result, tags(:ssd_legal)
  end

  test "listable_tags excludes hidden tags even for admin" do
    user   = users(:admin)
    tenant = tenants(:ssd)
    refute_includes user.listable_tags(tenant), tags(:ssd_hidden)
  end

  test "accessible_or_unrestricted_tags excludes access tags for non-members" do
    user   = users(:ssd_signer)
    tenant = tenants(:ssd)

    refute_includes user.accessible_or_unrestricted_tags(tenant), tags(:ssd_access_tag)
  end

  test "accessible_or_unrestricted_tags preserves non-visible unrestricted tags" do
    user   = users(:basic)
    tenant = tenants(:ssd)

    assert_includes user.accessible_or_unrestricted_tags(tenant), tags(:ssd_hidden)
  end

  # --- manageable_simple_tags (delegated to listable_tags + .simple) ---

  test "manageable_simple_tags includes ordinary tags for non-admin user" do
    user   = users(:basic)
    tenant = tenants(:ssd)
    # ssd_legal has no tag_groups → ordinary tag, always visible
    assert_includes user.manageable_simple_tags(tenant), tags(:ssd_legal)
  end

  test "manageable_simple_tags includes access tag for member of its group" do
    # basic user is in ssd_basic_user group which is the only group for ssd_access_tag
    user   = users(:basic)
    tenant = tenants(:ssd)
    assert_includes user.manageable_simple_tags(tenant), tags(:ssd_access_tag)
  end

  test "manageable_simple_tags excludes access tag for non-member" do
    # ssd_signer is in ssd_signer_user, NOT ssd_basic_user
    user   = users(:ssd_signer)
    tenant = tenants(:ssd)
    refute_includes user.manageable_simple_tags(tenant), tags(:ssd_access_tag)
  end

  test "manageable_simple_tags includes all simple visible tags for admin" do
    user   = users(:admin)
    tenant = tenants(:ssd)
    result = user.manageable_simple_tags(tenant)
    assert_includes result, tags(:ssd_access_tag)
    assert_includes result, tags(:ssd_legal)
  end

  test "manageable_simple_tags excludes non-simple tags" do
    user   = users(:basic)
    tenant = tenants(:ssd)
    # ssd_archived is ArchivedTag (visible: true, no access groups) - not a SimpleTag
    refute_includes user.manageable_simple_tags(tenant), tags(:ssd_archived)
  end
end
