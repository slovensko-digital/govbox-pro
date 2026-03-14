class Api::Fs::ApiConnectionsController < Api::TenantController
  def index
    @api_connections = @tenant.api_connections.where(type: "Fs::ApiConnection").order(:id)
  end

  def boxify
    @api_connection = @tenant.api_connections.where(type: "Fs::ApiConnection").find(params[:id])

    @new_boxes_count = @api_connection.boxify
  end
end
