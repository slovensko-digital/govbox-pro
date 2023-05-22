class AddTypeToGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :type, :string
  end
end
