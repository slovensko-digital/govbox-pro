class UpdateMessageThreadMergeIdentifiersUniqueConstraint < ActiveRecord::Migration[7.0]
  def change
    remove_index :message_thread_merge_identifiers, :uuid, unique: true
    add_index :message_thread_merge_identifiers, [:uuid, :tenant_id], unique: true
  end
end
