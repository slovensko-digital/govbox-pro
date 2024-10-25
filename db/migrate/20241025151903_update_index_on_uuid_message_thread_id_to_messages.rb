class UpdateIndexOnUuidMessageThreadIdToMessages < ActiveRecord::Migration[7.1]
  def change
    remove_index :messages, name: 'index_messages_on_uuid_and_message_thread_id'

    add_unique_constraint :messages, [:uuid, :message_thread_id], deferrable: :deferred
  end
end

