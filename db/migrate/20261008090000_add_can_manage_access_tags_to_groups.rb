class AddCanManageAccessTagsToGroups < ActiveRecord::Migration[7.1]
  def up
    add_column :groups, :can_manage_access_tags, :boolean, default: false, null: false

    # Grandfather existing groups so the new permission does not break anyone.
    Group.update_all(can_manage_access_tags: true)
  end

  def down
    remove_column :groups, :can_manage_access_tags
  end
end
