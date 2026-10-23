class Admin::BoxGroupsController < ApplicationController
  before_action :set_box_group, only: [:destroy]

  def create
    @box_group = BoxGroup.new(box_group_params)

    box = Current.tenant.boxes.find_by(id: @box_group.box_id)
    unless box
      redirect_to admin_tenant_groups_url(Current.tenant), alert: "Zvolená schránka neexistuje" and return
    end

    authorize([:admin, @box_group])

    @box_group.save!
    redirect_to edit_permissions_admin_tenant_group_url(Current.tenant, @box_group.group), notice: "Prístup ku schránke bol úspešne priradený"
  end

  def destroy
    authorize([:admin, @box_group])

    @box_group.destroy
    redirect_to edit_permissions_admin_tenant_group_url(Current.tenant, @box_group.group), notice: "Prístup ku schránke bol úspešne odstránený"
  end

  private

  def set_box_group
    @box_group = policy_scope([:admin, BoxGroup]).find(params[:id])
  end

  def box_group_params
    params.permit(:box_id, :group_id)
  end
end
