class Api::SiteAdmin::Stats::TenantsController < Api::SiteAdminController
  before_action :set_tenant

  def users_count
    @users_count = @tenant.users.count
  end

  def messages_per_period
    stats = Api::SiteAdmin::Stats::Tenant.new(params)
    stats.validate!
    @messages_per_period = @tenant.messages.where("messages.created_at between ? and ?", stats.from, stats.to).count
  end

  def messages_count
    @messages_count = @tenant.messages.count
  end

  private

  def tenant_params
    params.require(:tenant).permit(:name, { admin: [:name, :email] })
  end
end
