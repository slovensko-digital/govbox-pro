class AddUuidToMessageObjects < ActiveRecord::Migration[7.1]
  def change
    add_column :message_objects, :uuid, :uuid
  end
end
