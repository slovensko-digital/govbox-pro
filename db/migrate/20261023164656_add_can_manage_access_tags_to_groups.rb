# frozen_string_literal: true

class AddCanManageAccessTagsToGroups < ActiveRecord::Migration[8.1]
  def up
    add_column :groups, :can_manage_access_tags, :boolean, default: false, null: false

    # Only admin groups get the permission, other groups require an explicit grant
    execute "UPDATE groups SET can_manage_access_tags = TRUE WHERE type = 'AdminGroup'"
  end

  def down
    remove_column :groups, :can_manage_access_tags
  end
end
