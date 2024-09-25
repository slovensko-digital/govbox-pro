class RemoveIsPinnedFromFilters < ActiveRecord::Migration[7.1]
  def up
    remove_column :filters, :is_pinned
  end

  def down
    add_column :filters, :is_pinned, :boolean, null: false, default: false
    add_index :filters, :is_pinned
  end
end
