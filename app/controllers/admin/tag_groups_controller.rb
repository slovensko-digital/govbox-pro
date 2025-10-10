class Admin::TagGroupsController < ApplicationController
  before_action :set_tag_group, only: %i[destroy]
  # TODO: rediscuss the whole concept of SITE_ADMIN vs TENANT admin responsibilities and functionality

  # TODO: Toto je trochu nestastne, ze to nastavuje skupiny. Komponent, co listuje vsetky TagGroups ale naozaj listuje skupiny, a k nim potom tagy. Keby som to daval pod skupiny, tak asi pod samostatnu akciu, aby som odlisil na aky komponent idem (kedze je to iny, ako pre administraciu skupin)
  def index
    authorize([:admin, TagGroup])
    @groups = policy_scope([:admin, Group])
  end

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
