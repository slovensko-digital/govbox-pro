class AddEncodingToObjectData < ActiveRecord::Migration[7.0]
  def change
    add_column :message_objects, :encoding, :string, null: false
  end
end
