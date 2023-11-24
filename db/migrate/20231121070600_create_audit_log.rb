class CreateAuditLog < ActiveRecord::Migration[7.0]
  def change
    create_table :audit_logs do |t|
      t.string :type, null: false
      t.references :tenant, foreign_key: { on_delete: :nullify }
      t.timestamp :happened_at, null: false
      t.string :actor_name
      t.references :actor, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :previous_value # contains highlighted change - previous value
      t.string :new_value # contains highlighted change - new value
      t.jsonb :changeset  # contains all relevant changes including highlighted changes
      t.references :message_thread, foreign_key: { on_delete: :nullify }
      t.integer :thread_id_archived # in case the thread gets deleted
      t.string :thread_title # in case the thread gets deleted
      t.timestamps
    end

    add_index :audit_logs, [:tenant_id, :actor_id, :happened_at]
    add_index :audit_logs, [:tenant_id, :message_thread_id, :happened_at], name: "index_audit_logs_on_tenant_id_thread_id_happened_at"
  end
end
