class Admin::AuditLogsController < ApplicationController
  before_action :set_audit_logs

  def index
    authorize [:admin, AuditLog]
    respond_to do |format|
      format.html
      format.csv do
        send_data @audit_logs.to_csv, filename: "audit-logs-user-#{@user.id}.csv" if @user
        send_data @audit_logs.to_csv, filename: "audit-logs-thread-#{@thread.id}.csv" if @thread
      end
    end
  end

  def scroll
    authorize [:admin, AuditLog]
  end

  def set_audit_logs
    cursor = params[:cursor]
    @audit_logs = policy_scope([:admin, AuditLog]).order(happened_at: :desc, id: :desc)
    @audit_logs = @audit_logs.limit(50) unless request.format.csv?
    @audit_logs = @audit_logs.where("(happened_at, id) < (?, ?)", from_millis(cursor[:happened_at].to_f), cursor[:id]) if cursor
    set_audit_subject
    return unless @audit_logs.any?

    set_next
  end

  def set_audit_subject
    if params[:user_id]
      @user = policy_scope([:admin, User]).find(params[:user_id])
      @audit_logs = @audit_logs.where(user: @user)
    end
    return unless params[:message_thread_id]

    @thread = policy_scope(MessageThread).find(params[:message_thread_id])
    @audit_logs = @audit_logs.where(thread: @thread)
  end

  def set_next
    @next_cursor = { happened_at: to_millis(@audit_logs.last.happened_at), id: @audit_logs.last.id }
    if @user
      @url = scroll_admin_tenant_user_audit_logs_path(Current.tenant, Current.user, cursor: @next_cursor, format: :turbo_stream)
    elsif @thread
      @url = scroll_message_thread_audit_logs_path(@thread, cursor: @next_cursor, format: :turbo_stream)
    end
  end

  def to_millis(time)
    time.strftime("%s%L")
  end

  def from_millis(millis)
    Time.zone.at(millis / 1000)
  end
end
