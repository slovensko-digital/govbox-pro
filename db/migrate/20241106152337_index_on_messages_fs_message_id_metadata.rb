class IndexOnMessagesFsMessageIdMetadata < ActiveRecord::Migration[7.1]
  def up
    execute "CREATE INDEX index_messages_on_metadata_fs_message_id ON messages USING HASH (((metadata->>'fs_message_id')::text))"
  end

  def down
    remove_index :messages, name: :index_messages_on_metadata_fs_message_id
  end
end
