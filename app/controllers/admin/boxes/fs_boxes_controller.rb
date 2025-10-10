class Admin::Boxes::FsBoxesController < Admin::BoxesController
  def update
    authorize([:admin, @box])
    if @box.update(uri: "dic://sk/#{box_params.require(:settings_dic)}", **box_params)
      redirect_to admin_tenant_boxes_url(Current.tenant), notice: "Box bol úspešne upravený"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def box_params
    params.require(:fs_box).permit(:name, :short_name, :export_name, :color, :settings_dic, :syncable)
  end
end
