class Admin::ApiConnections::FsApiConnectionsController < Admin::ApiConnectionsController
  def update
    authorize([:admin, @api_connection])
    if @api_connection.update(api_connection_params)
      redirect_to admin_tenant_api_connections_url(Current.tenant), notice: "API prepojenie bolo úspešne upravené"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    @api_connection = Current.tenant.api_connections.new(type: "Fs::ApiConnection")
    authorize([:admin, @api_connection])
  end

  def boxify
    authorize([:admin, @api_connection])
    count = @api_connection.boxify
    redirect_to admin_tenant_api_connections_url(Current.tenant), notice: "API connection created #{count} new FS boxes."
  end

  private

  def api_connection_params
    params.require(:fs_api_connection).permit(:tenant_id, :custom_name, :settings_username, :settings_password)
  end
end
