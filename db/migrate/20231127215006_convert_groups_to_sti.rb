class ConvertGroupsToSti < ActiveRecord::Migration[7.0]
  def up
    add_column :groups, :type, :string, null: true

    Group.find_each do |group|
      type = case group.group_type
               when "ALL"
                 "AllGroup"
               when "ADMIN"
                 "AdminGroup"
               when "USER"
                 "UserGroup"
               when "CUSTOM"
                 "CustomGroup"
             end

      group.update_column(:type, type)
    end

    change_column_null :groups, :type, false
    change_column_null :groups, :group_type, true
  end

  def down
    change_column_null :groups, :group_type, false
    remove_column :groups, :type
  end
end
