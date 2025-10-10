class Admin::Boxes::UpvsBoxesController < Admin::BoxesController
  def new
    @box = Current.tenant.boxes.new(type: "Upvs::Box")
    authorize([:admin, @box])
  end

  def create
    api_connection = Current.tenant.api_connections.find(box_params[:api_connection_id])
    @box = Current.tenant.boxes.new(**box_params.except(:api_connection_id).merge(type: 'Upvs::Box', api_connections: [api_connection]))

    authorize([:admin, @box])
    if @box.save
      redirect_to admin_tenant_boxes_url(Current.tenant), notice: "Box bol úspešne vytvorený"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize([:admin, @box])
    if @box.update(type: "Upvs::Box", **box_params.except(:api_connection_id))
      redirect_to admin_tenant_boxes_url(Current.tenant), notice: "Box bol úspešne upravený"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def box_params
    params.require(:upvs_box).permit(:api_connection_id, :name, :uri, :short_name, :export_name, :color, :settings_obo)
  end
end
