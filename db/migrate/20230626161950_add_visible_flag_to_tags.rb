class AddVisibleFlagToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :visible, :boolean, default: true, null: false
  end
end
