class Admin::FsApiConnectionsController < Admin::ApiConnectionsController
  def create
    @api_connection = Current.tenant.api_connections.new(api_connection_params)
    authorize([:admin, @api_connection])
    if @api_connection.save!
      redirect_to admin_tenant_api_connections_url(Current.tenant), notice: "API connection was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize([:admin, @api_connection])
    if @api_connection.update(api_connection_params)
      redirect_to admin_tenant_api_connections_url(Current.tenant), notice: "API connection was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    @api_connection = Current.tenant.api_connections.new(type: "Fs::ApiConnection")
    authorize([:admin, @api_connection])
  end

  private

  def api_connection_params
    params.require(:fs_api_connection).permit(:tenant_id, :api_token_private_key, :settings_username, :settings_password, :obo, :sub, :type)
  end
end
