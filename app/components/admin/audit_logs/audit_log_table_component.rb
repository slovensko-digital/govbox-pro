class Admin::AuditLogs::AuditLogTableComponent < ViewComponent::Base
  renders_one :next_page_area
  def initialize(audit_logs:, view:, actor: nil, message_thread: nil)
    @actor = actor
    @message_thread = message_thread
    @audit_logs = audit_logs
    @view = view
  end
end
