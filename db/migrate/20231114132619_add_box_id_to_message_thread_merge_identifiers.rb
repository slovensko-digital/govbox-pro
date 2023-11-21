class AddBoxIdToMessageThreadMergeIdentifiers < ActiveRecord::Migration[7.0]
  def change
    add_reference :message_thread_merge_identifiers, :box, null: true, index: true

    MessageThreadMergeIdentifier.find_each do |merge_identifier|
      merge_identifier.update(box: merge_identifier.message_thread.box)
    end

    change_column_null :message_thread_merge_identifiers, :box_id, false
    remove_column :message_thread_merge_identifiers, :tenant_id

    add_index :message_thread_merge_identifiers, [:uuid, :box_id], unique: true
  end
end
