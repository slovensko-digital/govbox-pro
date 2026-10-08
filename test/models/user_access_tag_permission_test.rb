require "test_helper"

class UserAccessTagPermissionTest < ActiveSupport::TestCase
  setup do
    @tenant = tenants(:ssd)
    @user = users(:basic)
    @admin = users(:admin)
  end

  test "can_manage_access_tags? is false by default" do
    refute @user.can_manage_access_tags?
  end

  test "can_manage_access_tags? is true when one of the user's groups has the permission" do
    groups(:ssd_basic_user).update!(can_manage_access_tags: true)

    assert @user.can_manage_access_tags?
  end

  test "can_manage_access_tags? is true for an admin" do
    assert @admin.can_manage_access_tags?
  end

  test "new groups do not manage access tags by default" do
    group = @tenant.groups.create!(name: "New group", type: "CustomGroup")

    refute group.can_manage_access_tags
  end
end
