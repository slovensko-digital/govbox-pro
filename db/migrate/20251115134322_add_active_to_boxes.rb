class AddActiveToBoxes < ActiveRecord::Migration[7.1]
  def change
    add_column :boxes, :active, :boolean, default: true, null: false
  end
end
