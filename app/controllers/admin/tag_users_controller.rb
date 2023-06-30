class Admin::TagUsersController < ApplicationController
  before_action :set_tag_user, only: %i[ destroy ]
  # TODO - rediscuss the whole concept of SITE_ADMIN vs TENANT admin responsibilities and functionality

  def create
    @tag_user = TagUser.new(tag_user_params)
    authorize([:admin, @tag_user])

    if @tag_user.save
      redirect_back fallback_location:"/", notice: "Tag permission was successfully assigned."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize([:admin, @tag_user])
    @tag_user.destroy
    redirect_back fallback_location:"/", notice: "Tag permission was successfully destroyed."
  end

  private

  def set_tag_user
    @tag_user = policy_scope([:admin, TagUser]).find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def tag_user_params
    params.require(:tag_user).permit(:tag_id, :user_id)
  end
end
