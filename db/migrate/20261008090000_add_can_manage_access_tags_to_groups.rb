class AddCanManageAccessTagsToGroups < ActiveRecord::Migration[7.1]
  def up
    add_column :groups, :can_manage_access_tags, :boolean, default: false, null: false

    # Grandfather existing groups (admin groups included) so the new permission
    # does not break anyone. New admin groups get it on creation.
    Group.update_all(can_manage_access_tags: true)
  end

  def down
    remove_column :groups, :can_manage_access_tags
  end
end
