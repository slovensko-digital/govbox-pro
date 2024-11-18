class AddUniqueIndexOnUuidMessageThreadIdToMessages < ActiveRecord::Migration[7.0]
  def up
    add_index :messages, [:uuid, :message_thread_id], unique: true
  end

  def down
    remove_index :messages, [:uuid, :message_thread_id], unique: true
  end
end

