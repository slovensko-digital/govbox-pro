class AddTypeToFilters < ActiveRecord::Migration[7.1]
  def up
    add_column :filters, :icon, :string, null: true
    add_column :filters, :type, :string, null: true

    Filter.where(type: nil).update_all(type: 'FulltextFilter')

    change_column_null :filters, :name, false

    add_index :filters, :type
  end

  def down
    Filter.where.not(type: 'FulltextFilter').delete_all

    remove_column :filters, :icon
    remove_column :filters, :type
  end
end
