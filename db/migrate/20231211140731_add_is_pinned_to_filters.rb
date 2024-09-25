class AddIsPinnedToFilters < ActiveRecord::Migration[7.1]
  def change
    add_column :filters, :is_pinned, :boolean, null: false, default: false
    add_index :filters, :is_pinned
  end
end
