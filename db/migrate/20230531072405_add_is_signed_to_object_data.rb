class AddIsSignedToObjectData < ActiveRecord::Migration[7.0]
  def change
    add_column :message_objects, :is_signed, :boolean
  end
end
