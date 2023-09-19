class AddShortNameToBoxes < ActiveRecord::Migration[7.0]
  def change
    add_column :boxes, :short_name, :string
    add_index :boxes, %i[tenant_id short_name], unique: true
  end
end
