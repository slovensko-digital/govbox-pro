class Admin::TagGroupsController < ApplicationController
  before_action :set_tag_group, only: %i[ destroy ]
  # TODO - rediscuss the whole concept of SITE_ADMIN vs TENANT admin responsibilities and functionality

  def create
    @tag_group = TagGroup.new(tag_group_params)
    authorize([:admin, @tag_group])

    @tag_group.save!

    redirect_back fallback_location:"/", notice: "Tag permission was successfully assigned."
  end

  def destroy
    authorize([:admin, @tag_group])
    @tag_group.destroy
    redirect_back fallback_location:"/", notice: "Tag permission was successfully destroyed."
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
