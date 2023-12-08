class Api::Admin::BoxesController < ActionController::Base
  include AuditableApiEvents
  before_action :set_tenant
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def create
    begin
      @box = @tenant.boxes.new(box_params)
    rescue ActionController::ParameterMissing, ActiveRecord::NotFound => e
      @exception = e
    end

    return if @box.save

    render :error, status: :unprocessable_entity
    log_api_call(:create_tenant_box_api_called)
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:tenant_id])
  end

  def box_params
    params.require(:box).permit(:id, :name, :short_name, :uri, :color, :api_connection_id)
  end
end
