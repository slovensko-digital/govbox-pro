class Api::SiteAdmin::TenantsController < Api::SiteAdminController
  before_action :set_tenant, only: %i[destroy update]

  def create
    Tenant.transaction do
      @tenant = Tenant.create_with_admin!(tenant_params, tenant_params.require(:admin))
    end

    render status: :created
  end

  def update
    @tenant.update!(tenant_params)
  end

  def destroy
    Tenant.find(params[:id]).destroy!
  end

  private

  def tenant_params
    params.require(:tenant).permit(:name, :active_until, :feature_flags, { admin: [:name, :email] })
  end
end
