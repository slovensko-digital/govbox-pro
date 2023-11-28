class Admin::TenantsController < ApplicationController
  before_action :set_tenant, only: %i[show edit update destroy]

  def index
    authorize([:admin, Tenant])
    @tenants = policy_scope([:admin, Tenant]).order(:name)
  end

  def show
    @tenant = policy_scope([:admin, Tenant]).find(params[:id])
    authorize([:admin, @tenant])
    session[:tenant_id] = @tenant.id
    Current.tenant = @tenant
  end

  def new
    @tenant = Tenant.new
    authorize([:admin, @tenant])
  end

  def edit
    authorize([:admin, @tenant])
  end

  def create
    @tenant = Tenant.new(tenant_params)
    authorize([:admin, @tenant])
    if @tenant.save
      redirect_to admin_tenants_url, notice: 'Tenant was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tenants/1 or /tenants/1.json
  def update
    authorize([:admin, @tenant])
    if @tenant.update(tenant_params)
      redirect_to admin_tenants_url, notice: 'Tenant was successfully updated'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /tenants/1 or /tenants/1.json
  def destroy
    authorize([:admin, @tenant])
    @tenant.destroy
    session[:tenant_id] = nil if Current.tenant == @tenant
    redirect_to admin_tenants_url, notice: 'Tenant was successfully destroyed'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tenant
    @tenant = Tenant.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def tenant_params
    params.require(:tenant).permit(:name)
  end
end
