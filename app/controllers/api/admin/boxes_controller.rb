class Api::Admin::BoxesController < ActionController::Base
  before_action :set_tenant
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def create
    @box = @tenant.boxes.new(box_params)
    #    authorize([:admin, @box])
    return if @box.save

    render json: { message: @box.errors.full_messages[0] }, status: :unprocessable_entity
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:tenant_id])
  end

  def box_params
    params.require(:box).permit(:id, :name, :short_name, :uri, :color, :api_connection_id)
  end

  def not_found
    render json: { message: 'not found' }, status: :not_found
  end
end
