class AddGroupTypeToGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :group_type, :string
  end
end
