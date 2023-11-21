class CreateAuditLog < ActiveRecord::Migration[7.0]
  def change
    create_table :audit_logs do |t|
      t.string :type, null: false
      t.references :tenant, foreign_key: { on_delete: :nullify }
      t.timestamp :happened_at, null: false
      t.string :user_name
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :previous_value # contains highlighted change - previous value
      t.string :new_value # contains highlighted change - new value
      t.jsonb :changeset  # contains all relevant changes including highlighted changes
      t.references :thread, foreign_key: { to_table: :message_threads, on_delete: :nullify }
      t.integer :thread_id_archived # in case the thread gets deleted
      t.string :thread_name # in case the thread gets deleted
      t.timestamps
    end

    add_index :audit_logs, [:tenant_id, :user_id, :happened_at]
    add_index :audit_logs, [:tenant_id, :thread_id, :happened_at]
  end
end
