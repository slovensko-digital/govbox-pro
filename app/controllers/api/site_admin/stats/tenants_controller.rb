class Api::SiteAdmin::Stats::TenantsController < Api::SiteAdminController
  include AuditableApiEvents
  before_action :set_tenant
  rescue_from ActiveRecord::RecordNotFound, with: :handle_exception
  rescue_from ActionController::ParameterMissing, with: :handle_exception

  def users_count
    @users_count = @tenant.users.count
    render :error, status: :unprocessable_entity unless @tenant
  end

  def messages_per_period
    from_period = Time.zone.parse(params[:from])
    to_period = Time.zone.parse(params[:to])
    if @tenant && from_period && to_period
      @messages_per_period = Message.joins(thread: :box)
                                    .where(box: { tenant_id: @tenant.id })
                                    .where("messages.created_at between ? and ?", from_period, to_period)
                                    .count
    else
      @period_error = "Period from missing" unless from_period
      @period_error = "Period to missing" unless to_period
      render :error_messages_per_period, status: :unprocessable_entity
    end
  end

  def messages_count
    @messages_count = Message.joins(thread: :box).where(box: { tenant_id: @tenant.id }).count
    render :error, status: :unprocessable_entity unless @tenant
  end

  private

  def tenant_params
    params.require(:tenant).permit(:name, { admin: [:name, :email] })
  end

  def handle_exception(exception)
    @exception = exception
    render :error, status: :unprocessable_entity
  end
end
