class AddIconToFilters < ActiveRecord::Migration[7.1]
  def change
    add_column :filters, :icon, :string
  end
end
