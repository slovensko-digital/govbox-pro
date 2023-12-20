class Api::SiteAdmin::TenantsController < Api::SiteAdminController
  before_action :set_tenant, only: %i[destroy]

  def create
    Tenant.transaction do
      @tenant = Tenant.create_with_admin!(tenant_params, tenant_params.require(:admin))
    end
  end

  def destroy
    @tenant.destroy
  end

  private

  def tenant_params
    params.require(:tenant).permit(:name, :feature_flags, { admin: [:name, :email] })
  end
end
