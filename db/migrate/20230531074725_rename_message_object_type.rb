class RenameMessageObjectType < ActiveRecord::Migration[7.0]
  def change
    rename_column :message_objects, :type, :object_type
  end
end
