class AddCanManageAccessTagsToGroups < ActiveRecord::Migration[7.1]
  def up
    add_column :groups, :can_manage_access_tags, :boolean, default: false, null: false

    # Non-admin groups require an explicit grant, including existing groups.
    execute "UPDATE groups SET can_manage_access_tags = TRUE WHERE type = 'AdminGroup'"
  end

  def down
    remove_column :groups, :can_manage_access_tags
  end
end
