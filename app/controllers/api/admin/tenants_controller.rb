class Api::Admin::TenantsController < ActionController::Base
  before_action :set_tenant, only: %i[destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def create
    #    authorize([:admin, Tenant])
    @tenant = Tenant.create(tenant_params)
    @admin = User.create(admin_params.merge(tenant_id: @tenant.id)) if @tenant
    @group_membership = @tenant.admin_group.users.push(@admin) if @tenant && @admin
    return if @tenant && @admin && @group_membership

    render json: {
      message: @tenant.errors.full_messages[0] ||
               @admin.errors.full_messages[0] ||
               @group_membership.errors.full_messages[0]
    }, status: :unprocessable_entity
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

  def admin_params
    params.require(:admin).permit(:name, :email)
  end

  def not_found
    render json: { message: 'not found' }, status: :not_found
  end
end
