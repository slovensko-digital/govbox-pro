class AddSyncableFlagToBoxes < ActiveRecord::Migration[7.0]
  def change
    add_column :boxes, :syncable, :boolean, null: false, default: true
  end
end
