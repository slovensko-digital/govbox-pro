class Admin::AuditLogs::AuditLogTableRowComponent < ViewComponent::Base
  with_collection_parameter :audit_log_item
  def initialize(audit_log_item:)
    @audit_log_item = audit_log_item
  end
end
