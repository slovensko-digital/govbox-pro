class EnableAccessTagManagementForAdminGroups < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE groups SET can_manage_access_tags = TRUE
      WHERE type = 'AdminGroup' AND can_manage_access_tags = FALSE
    SQL
  end

  def down
    # Do not revoke admin permissions when rolling back the repair.
  end
end
