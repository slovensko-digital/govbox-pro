class ConvertGroupsToSti < ActiveRecord::Migration[7.0]
  def up
    add_column :groups, :type, :string, null: true

    Group.find_each do |group|
      type = case group.group_type
               when 'ALL'
                 'GroupAll'
               when 'ADMIN'
                 'GroupAdmin'
               when 'USER'
                 'GroupUser'
               when 'CUSTOM'
                 'GroupCustom'
             end

      group.update_column(:type, type)
    end

    change_column_null :groups, :type, false
    change_column_null :groups, :group_type, true
  end

  def down
    remove_column :groups, :type
  end
end
