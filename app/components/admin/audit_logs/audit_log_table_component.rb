class Admin::AuditLogs::AuditLogTableComponent < ViewComponent::Base
  renders_one :next_page_area
  def initialize(audit_logs:, user: nil, message_thread: nil)
    @user = user
    @message_thread = message_thread
    @audit_logs = audit_logs
  end
end
