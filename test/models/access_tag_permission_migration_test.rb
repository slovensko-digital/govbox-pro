require "test_helper"
require Rails.root.join("db/migrate/20261008090000_add_can_manage_access_tags_to_groups")
require Rails.root.join("db/migrate/20261008210000_enable_access_tag_management_for_admin_groups")

class AccessTagPermissionMigrationTest < ActiveSupport::TestCase
  test "repair enables existing admin groups without changing other permissions" do
    admin_group = groups(:ssd_admins)
    disabled_group = groups(:ssd_custom)
    enabled_group = groups(:ssd_basic_user)
    admin_group.update_column(:can_manage_access_tags, false)
    disabled_group.update!(can_manage_access_tags: false)
    enabled_group.update!(can_manage_access_tags: true)

    migration = EnableAccessTagManagementForAdminGroups.new
    migration.migrate(:up)

    assert admin_group.reload.can_manage_access_tags
    refute disabled_group.reload.can_manage_access_tags
    assert enabled_group.reload.can_manage_access_tags

    migration.migrate(:down)
    assert admin_group.reload.can_manage_access_tags
  end

  test "migration preserves existing groups and defaults new groups to false and rolls back" do
    connection = Group.connection

    connection.transaction(requires_new: true) do
      connection.remove_column :groups, :can_manage_access_tags
      Group.reset_column_information

      migration = AddCanManageAccessTagsToGroups.new
      migration.migrate(:up)
      Group.reset_column_information

      assert Group.exists?
      refute Group.exists?(can_manage_access_tags: false)
      group = tenants(:ssd).custom_groups.create!(name: "New group after migration")
      refute group.can_manage_access_tags

      migration.migrate(:down)
      refute connection.column_exists?(:groups, :can_manage_access_tags)

      raise ActiveRecord::Rollback
    end
  ensure
    Group.reset_column_information
  end
end
