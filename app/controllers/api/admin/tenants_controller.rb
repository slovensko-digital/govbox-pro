class Api::Admin::TenantsController < ActionController::Base
  before_action :set_tenant, only: %i[destroy]
  def create
    @tenant = Tenant.new(tenant_params)
    #    authorize([:admin, @tenant])
    respond_to do |format|
      if @tenant.save
        format.json { render json: @tenant, status: :created }
      else
        format.json { render json: @tenant.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    # authorize([:admin, @tenant])
    respond_to do |format|
      if @tenant.destroy
        format.json { render json: {}, status: :ok }
      else
        format.json { render json: @tenant.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:id])
  end

  def tenant_params
    params.require(:tenant).permit(:name)
  end
end
