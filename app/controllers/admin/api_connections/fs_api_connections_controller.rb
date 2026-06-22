class Admin::ApiConnections::FsApiConnectionsController < Admin::ApiConnectionsController
  def init
    authorize([:admin, @api_connection])

    return unless request.patch?

    if @api_connection.update(api_connection_params)
      boxify_and_redirect_from_init
    else
      render :init, status: :unprocessable_content
    end
  end

  def update
    authorize([:admin, @api_connection])
    if @api_connection.update(api_connection_params)
      redirect_to admin_tenant_api_connections_url(Current.tenant), notice: "API prepojenie bolo úspešne upravené"
    else
      render :edit, status: :unprocessable_content
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

  def boxify_and_redirect_from_init
    count = @api_connection.boxify
    redirect_to message_threads_path,
                notice: "Prepojenie s FS bolo úspešne nastavené. Vytvorených schránok: #{count}"
  rescue StandardError
    redirect_to init_admin_tenant_api_connections_fs_api_connection_path(Current.tenant, @api_connection),
                alert: "Prepojenie bolo uložené, ale schránky sa nepodarilo vytvoriť. Skúste uloženie zopakovať."
  end

  def api_connection_params
    params.require(:fs_api_connection).permit(:custom_name, :settings_username, :settings_password).compact_blank!
  end
end
