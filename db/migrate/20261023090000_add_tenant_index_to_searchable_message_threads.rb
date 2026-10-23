# frozen_string_literal: true

class AddTenantIndexToSearchableMessageThreads < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :searchable_message_threads, :tenant_id, algorithm: :concurrently
  end
end
