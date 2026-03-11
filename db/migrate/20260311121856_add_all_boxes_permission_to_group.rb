class AddAllBoxesPermissionToGroup < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :all_boxes_permission, :boolean, null: false, default: false
  end
end
