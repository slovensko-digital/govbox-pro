class TenantsController < ApplicationController
    before_action :set_tenant, only: %i[show edit update destroy]
  
    # GET /tenants or /tenants.json
    def index
      @tenants = Tenant.all
    end
  
    # GET /tenants/1 or /tenants/1.json
    def show; end
  
    # GET /tenants/new
    def new
      @tenant = Tenant.new
    end
  
    # GET /tenants/1/edit
    def edit; end
  
    # POST /tenants or /tenants.json
    def create
      @tenant = Tenant.new(tenant_params)
  
      respond_to do |format|
        if @tenant.save
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
      @tenant.destroy
  
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