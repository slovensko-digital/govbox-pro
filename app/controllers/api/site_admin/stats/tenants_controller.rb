class Api::SiteAdmin::Stats::TenantsController < Api::SiteAdminController
  before_action :set_tenant

  def users_count
    @users_count = @tenant.users.count
    render :error, status: :unprocessable_entity unless @tenant
    puts "no exception"
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
end
