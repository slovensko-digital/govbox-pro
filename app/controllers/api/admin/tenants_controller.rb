class Api::Admin::TenantsController < ActionController::Base
  before_action :set_tenant, only: %i[destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def create
    @tenant = Tenant.new(tenant_params)
    #    authorize([:admin, @tenant])
    return if @tenant.save

    render json: { message: @tenant.errors.full_messages[0] }, status: :unprocessable_entity
  end

  def destroy
    # authorize([:admin, @tenant])
    return if @tenant.destroy

    render json: { message: @tenant.errors.full_messages[0] }, status: :unprocessable_entity
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:id])
  end

  def tenant_params
    params.require(:tenant).permit(:name)
  end

  def not_found
    render json: { message: 'not found' }, status: :not_found
  end
end
