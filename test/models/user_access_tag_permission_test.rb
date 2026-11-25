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

  test "group access tag management permission must be a boolean" do
    group = groups(:ssd_custom)

    [nil, ""].each do |value|
      group.can_manage_access_tags = value

      refute group.valid?
      assert group.errors.of_kind?(:can_manage_access_tags, :inclusion)
    end

    [true, false].each do |value|
      group.can_manage_access_tags = value

      assert group.valid?
    end
  end

  test "permission granted to existing groups can be fully revoked" do
    @tenant.groups.update_all(can_manage_access_tags: true)
    assert @user.can_manage_access_tags?

    @user.groups.each { |group| group.update!(can_manage_access_tags: false) }

    refute @user.can_manage_access_tags?
  end
end
