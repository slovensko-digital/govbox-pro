class Api::SiteAdmin::TenantsController < Api::SiteAdminController
  include AuditableApiEvents
  before_action :set_tenant, only: %i[destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :handle_exception
  rescue_from ActionController::ParameterMissing, with: :handle_exception

  def create
    @tenant, @admin, @group_membership = Tenant.create_with_admin(tenant_params)
    render :error, status: :unprocessable_entity unless @group_membership
    log_api_call(:create_tenant_api_called)
  end

  def destroy
    return if @tenant.destroy

    render :error, status: :unprocessable_entity
    log_api_call(:create_tenant_api_called)
  end

  private

  def tenant_params
    params.require(:tenant).permit(:name, :feature_flags, { admin: [:name, :email] })
  end

  def save_exception(exception)
    @exception = exception
    render :error, status: :unprocessable_entity unless @group_membership
  end
end
