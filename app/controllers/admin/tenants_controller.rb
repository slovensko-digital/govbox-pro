class Admin::TenantsController < ApplicationController
  before_action :set_tenant, only: %i[show edit update destroy]

  def index
    authorize Tenant, policy_class: Admin::TenantPolicy
    @tenants = policy_scope(Tenant, policy_scope_class: Admin::TenantPolicy::Scope)
  end

  def show
    @tenant = policy_scope(Tenant, policy_scope_class: Admin::TenantPolicy::Scope).find(params[:id])
    authorize @tenant, policy_class: Admin::TenantPolicy
    session[:tenant_id] = @tenant.id
    Current.tenant = @tenant.id
  end

  def new
    @tenant = Tenant.new
    authorize @tenant, policy_class: Admin::TenantPolicy
  end

  def edit
    authorize @tenant, policy_class: Admin::TenantPolicy
  end

  def create
    @tenant = Tenant.new(tenant_params)
    authorize @tenant, policy_class: Admin::TenantPolicy
    respond_to do |format|
      if @tenant.save
        format.html { redirect_to admin_tenant_url(@tenant), notice: 'Tenant was successfully created.' }
        format.json { render :show, status: :created, location: @tenant }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tenant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tenants/1 or /tenants/1.json
  def update
    authorize @tenant, policy_class: Admin::TenantPolicy
    respond_to do |format|
      if @tenant.update(tenant_params)
        format.html { redirect_to admin_tenant_url(@tenant), notice: 'Tenant was successfully updated.' }
        format.json { render :show, status: :ok, location: @tenant }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tenant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tenants/1 or /tenants/1.json
  def destroy
    authorize @tenant, policy_class: Admin::TenantPolicy
    @tenant.destroy
    session[:tenant_id] = nil
    respond_to do |format|
      format.html { redirect_to admin_tenants_url, notice: 'Tenant was successfully destroyed.' }
      format.json { head :no_content }
    end
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