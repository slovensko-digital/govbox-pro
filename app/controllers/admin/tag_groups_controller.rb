class Admin::TagGroupsController < ApplicationController
  before_action :set_tag_group, only: %i[destroy]

  def create
    @tag_group = TagGroup.new(tag_group_params)
    authorize([:admin, @tag_group])
    @tag_group.save!
    redirect_to edit_permissions_admin_tenant_group_url(Current.tenant, @tag_group.group), notice: "Prístup na základe štítkov bol úspešne priradený"
  end

  def destroy
    authorize([:admin, @tag_group])
    @tag_group.destroy
    redirect_to edit_permissions_admin_tenant_group_url(Current.tenant, @tag_group.group), notice: "Prístup na základe štítkov bol úspešne odstránený"
  end

  private

  def set_tag_group
    @tag_group = policy_scope([:admin, TagGroup]).find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def tag_group_params
    params.require(:tag_group).permit(:tag_id, :group_id)
  end
end
