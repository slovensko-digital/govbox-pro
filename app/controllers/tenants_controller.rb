class TenantsController < ApplicationController
    before_action :set_tenant, only: %i[show edit update destroy]
  
    # GET /tenants or /tenants.json
    def index
      authorize Tenant
      @tenants = policy_scope(Tenant)
    end
  
    # GET /tenants/1 or /tenants/1.json
    def show
      @tenant = policy_scope(Tenant).find(params[:id])
      authorize @tenant
      session[:tenant_id] = @tenant.id
      Current.tenant = @tenant.id
    end
  
    # GET /tenants/new
    def new
      @tenant = Tenant.new
      authorize @tenant
    end
  
    # GET /tenants/1/edit
    def edit;
      authorize @tenant
    end
  
    # POST /tenants or /tenants.json
    def create
      @tenant = Tenant.new(tenant_params)
      authorize @tenant
      @group_all = @tenant.groups.new(name: 'All Tenant users - default system group', group_type: 'ALL')
      @group_admin = @tenant.groups.new(name: 'Tenant admins - default system group', group_type: 'ADMIN')

      respond_to do |format|
        if @tenant.save && @group_all.save
          format.html { redirect_to tenant_url(@tenant), notice: 'Tenant was successfully created.' }
          format.json { render :show, status: :created, location: @tenant }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @tenant.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PATCH/PUT /tenants/1 or /tenants/1.json
    def update
      authorize @tenant
      respond_to do |format|
        if @tenant.update(tenant_params)
          format.html { redirect_to tenant_url(@tenant), notice: 'Tenant was successfully updated.' }
          format.json { render :show, status: :ok, location: @tenant }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @tenant.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /tenants/1 or /tenants/1.json
    def destroy
      authorize @tenant
      @tenant.destroy
      session[:tenant_id] = nil
      respond_to do |format|
        format.html { redirect_to tenants_url, notice: 'Tenant was successfully destroyed.' }
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