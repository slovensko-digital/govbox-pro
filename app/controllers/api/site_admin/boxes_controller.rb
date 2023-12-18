class Api::SiteAdmin::BoxesController < Api::SiteAdminController
  before_action :set_tenant

  def create
    Box.transaction do
      @box = @tenant.boxes.create_with_api_connection!(box_params)
    end
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:tenant_id])
  end

  def box_params
    params.require(:box).permit(:id, :name, :short_name, :uri, :color, :api_connection_id,
                                settings: :obo, api_connection: [:sub, :api_token_private_key])
  end
end
