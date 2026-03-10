class Api::ApiConnectionsController < Api::TenantController
  def index
    @api_connections = @tenant.api_connections.order(:id)
  end

  def boxify
    @api_connection = @tenant.api_connections.find(params[:id])

    render_unprocessable_content("Only FS API connections support the boxify action") and return unless @api_connection.fs_type?

    @new_boxes_count = @api_connection.boxify
  end
end
