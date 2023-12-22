class Api::SiteAdmin::Stats::TenantsController < Api::SiteAdminController
  before_action :set_tenant

  def users_count
    @users_count = @tenant.users.count
  end

  def messages_per_period
    stats = Api::SiteAdmin::Stats::Tenant.new(period_params)
    if stats.valid?
      @messages_per_period = @tenant.messages.where("messages.created_at between ? and ?", stats.from, stats.to).count
    else
      render status: :bad_request, json: { message: stats.errors.first.full_message }
    end
  end

  def messages_count
    @messages_count = @tenant.messages.count
  end

  private

  def tenant_params
    params.require(:tenant).permit(:name, { admin: [:name, :email] })
  end

  def period_params
    params.permit(:from, :to)
  end
end
