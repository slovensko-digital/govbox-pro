class UpdateAuditLogsFromChangedToUpdated < ActiveRecord::Migration[7.0]
  def change
    AuditLog.connection.execute("update audit_logs set type = 'AuditLog::MessageThreadTagUpdated' where type = 'AuditLog::MessageThreadTagChanged'")
    AuditLog.connection.execute("update audit_logs set type = 'AuditLog::MessageThreadNoteUpdated' where type = 'AuditLog::MessageThreadNoteChanged'")
  end
end
