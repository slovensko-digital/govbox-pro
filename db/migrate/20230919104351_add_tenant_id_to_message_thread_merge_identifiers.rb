class AddTenantIdToMessageThreadMergeIdentifiers < ActiveRecord::Migration[7.0]
  def up
    add_reference :message_thread_merge_identifiers, :tenant, foreign_key: true

    MessageThreadMergeIdentifier.find_each { |merge_identifier| merge_identifier.update(tenant: merge_identifier.message_thread.folder.tenant) }

    change_column :message_thread_merge_identifiers, :tenant_id, :bigint, null: false, foreign_key: true
  end
end
