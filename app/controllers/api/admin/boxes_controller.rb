class Api::Admin::BoxesController < ActionController::Base
  include AuditableApiEvents
  before_action :set_tenant
  rescue_from ActiveRecord::RecordNotFound, with: :handle_exception
  rescue_from ActionController::ParameterMissing, with: :handle_exception
  rescue_from ArgumentError, with: :handle_exception

  def create
    @box = @tenant.boxes.create_with_api_connection(box_params)
    return if @box

    render :error, status: :unprocessable_entity
    log_api_call(:create_tenant_box_api_called)
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:tenant_id])
  end

  def box_params
    params.require(:box).permit(:id, :name, :short_name, :uri, :color, :api_connection_id,
                                settings: :obo, api_connection: [:sub, :api_token_private_key])
  end

  def handle_exception(exception)
    @exception = exception
    render :error, status: :unprocessable_entity
  end
end
