class CreateGoAuditLog < ActiveRecord::Migration[7.0]
  def change
    create_table :go_audit_logs do |t|
      t.string :type
      # TODO: chceme aj "human readable type"? Sem sa totiz do typu pridava AuditLog::, a do prezeratka by bolo lepsie to mat bez
      t.references :tenant, null: false
      t.timestamp :event_timestamp, null: false
      t.string :user_name
      t.references :user
      t.references :primary_object, polymorphic: true
      t.references :secondary_object, polymorphic: true
      t.string :description
      t.string :original_value_string
      t.string :new_value_string
      t.timestamps
    end

    add_index :go_audit_logs, [:tenant_id, :user_id, :event_timestamp], name: "index_go_audit_logs_tenant_user_timestamp"
    add_index :go_audit_logs, [:tenant_id, :primary_object_type, :primary_object_id, :event_timestamp], name: "index_go_audit_logs_tenant_primary_timestamp"
  end
end
