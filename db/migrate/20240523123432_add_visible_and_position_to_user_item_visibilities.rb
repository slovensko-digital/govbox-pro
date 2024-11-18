class AddVisibleAndPositionToUserItemVisibilities < ActiveRecord::Migration[7.1]
  def change
    add_column :user_item_visibilities, :visible, :boolean, null: false, default: true
    add_column :user_item_visibilities, :position, :integer, null: true
  end
end
