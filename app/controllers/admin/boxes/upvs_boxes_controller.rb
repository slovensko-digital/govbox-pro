class Admin::Boxes::UpvsBoxesController < Admin::BoxesController
  def new
    @box = Current.tenant.boxes.new(type: "Upvs::Box")
    authorize([:admin, @box])
  end

  def create
    @box = Current.tenant.boxes.new(type: "Upvs::Box", **box_params)
    authorize([:admin, @box])
    if @box.save
      redirect_to admin_tenant_boxes_url(Current.tenant), notice: "Box was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize([:admin, @box])
    if @box.update(type: "Upvs::Box", **box_params)
      redirect_to admin_tenant_boxes_url(Current.tenant), notice: "Box was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def box_params
    params.require(:upvs_box).permit(:api_connection_id, :name, :uri, :short_name, :color, :settings_obo)
  end
end
