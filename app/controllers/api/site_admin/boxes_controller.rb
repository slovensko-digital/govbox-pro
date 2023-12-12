class Api::SiteAdmin::BoxesController < Api::SiteAdminController
  before_action :set_tenant

  def create
    @box = @tenant.boxes.new(box_params)
    return if @box.save

    render :error, status: :unprocessable_entity
    log_api_call(:create_tenant_box_api_called)
  end

  private

  def box_params
    params.require(:box).permit(:id, :name, :short_name, :uri, :color, :api_connection_id)
  end
end
