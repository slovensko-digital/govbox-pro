require "test_helper"

class AdminGroupTest < ActiveSupport::TestCase
  test "new admin groups have access tag management enabled" do
    group = tenants(:ssd).groups.create!(name: "New admins", type: "AdminGroup")

    assert group.reload.can_manage_access_tags
    assert AdminGroup.new.can_manage_access_tags
  end

  test "admin groups cannot be created with access tag management disabled" do
    group = tenants(:ssd).groups.new(name: "Disabled admins", type: "AdminGroup", can_manage_access_tags: false)

    refute group.save
    assert group.errors.of_kind?(:can_manage_access_tags, :inclusion)
  end

  test "admin groups cannot have access tag management disabled" do
    group = groups(:ssd_admins)

    refute group.update(can_manage_access_tags: false)
    assert group.reload.can_manage_access_tags
  end
end
