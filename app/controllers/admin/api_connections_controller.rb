class Admin::ApiConnectionsController < ApplicationController
  before_action :set_api_connection, except: [:index, :new, :create]

  def index
    authorize [:admin, ApiConnection]
    @api_connections = Current.tenant.api_connections
  end

  def show
    raise NotImplementedError
  end

  def destroy
    authorize [:admin, @api_connection]
    @api_connection.destroy
    redirect_to admin_tenant_api_connections_url(Current.tenant), notice: 'API connection was successfully destroyed'
  end

  def new
    @api_connection = Current.tenant.api_connections.new
    authorize([:admin, @api_connection])
  end

  def edit
    authorize([:admin, @api_connection])
  end

  def update
    raise NotImplementedError
  end

  def create
    raise NotImplementedError
  end

  private

  def set_api_connection
    @api_connection = ApiConnection.find(params[:id])
  end
end
