class Api::Admin::TenantsController < ActionController::Base
  before_action :set_tenant, only: %i[destroy]
  def create
    @tenant = Tenant.new(tenant_params)
    #    authorize([:admin, @tenant])
    return if @tenant.save

    render json: @tenant.errors, status: :unprocessable_entity
  end

  def destroy
    # authorize([:admin, @tenant])
    return if @tenant.destroy

    render json: @tenant.errors, status: :unprocessable_entity
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:id])
  end

  def tenant_params
    params.require(:tenant).permit(:name)
  end
end
