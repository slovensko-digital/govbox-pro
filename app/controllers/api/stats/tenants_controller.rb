class Api::Stats::TenantsController < ActionController::Base
  include AuditableApiEvents
  before_action :set_tenant
  rescue_from ActiveRecord::RecordNotFound, with: :save_exception
  rescue_from ActionController::ParameterMissing, with: :save_exception

  def users_count
    @users_count = @tenant.users.count
    render :error, status: :unprocessable_entity unless @tenant
  end

  def messages_per_period
    from_period = Time.zone.parse(params[:from])
    till_period = Time.zone.parse(params[:till])
    if @tenant && from_period && till_period
      @messages_per_period = Message.joins(thread: :box).where(box: { tenant_id: @tenant.id }).where("messages.created_at between ? and ?", from_period, till_period).count
    else
      @period_error = "From period missing" unless from_period
      @period_error = "Till period missing" unless till_period
      render :error_messages_per_period, status: :unprocessable_entity
    end
  end

  def messages_count
    @messages_count = Message.joins(thread: :box).where(box: { tenant_id: @tenant.id }).count
    render :error, status: :unprocessable_entity unless @tenant
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:tenant_id])
  end

  def tenant_params
    params.require(:tenant).permit(:name, { admin: [:name, :email] })
  end

  def save_exception(exception)
    @exception = exception
  end
end
