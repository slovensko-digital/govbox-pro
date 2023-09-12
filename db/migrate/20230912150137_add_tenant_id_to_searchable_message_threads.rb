class AddTenantIdToSearchableMessageThreads < ActiveRecord::Migration[7.0]
  def change
    add_column :searchable_message_threads, :tenant_id, :integer, null: true

    ::Searchable::MessageThread.includes(message_thread: { folder: :box }).find_each do |smt|
      smt.tenant_id = smt.message_thread.folder.box.tenant_id
      smt.save!
    end

    change_column_null :searchable_message_threads, :tenant_id, false
  end
end
