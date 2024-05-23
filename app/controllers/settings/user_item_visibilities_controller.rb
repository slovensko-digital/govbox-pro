class Settings::UserItemVisibilitiesController < ApplicationController
  before_action :set_user_item_visibility, only: [:update, :move_higher, :move_lower, :destroy]

  def index
    authorize UserItemVisibility

    set_type
    set_user_item_visibilities
  end

  def create
    authorize UserItemVisibility
    Current.user.user_item_visibilities.create(user_item_visibility_params).tap do |visibility|
      visibility.move_to_bottom
    end
    redirect_back fallback_location: request.referer
  end

  def update
    authorize @user_item_visibility
    @user_item_visibility.update(user_item_visibility_params)
    redirect_back fallback_location: request.referer
  end

  def move_higher
    authorize @user_item_visibility
    @user_item_visibility.move_higher
    redirect_back fallback_location: request.referer
  end

  def move_lower
    authorize @user_item_visibility
    @user_item_visibility.move_lower
    redirect_back fallback_location: request.referer
  end

  def destroy
    authorize @user_item_visibility
    @user_item_visibility.destroy
    redirect_back fallback_location: request.referer
  end

  private

  def set_type
    raise NotImplementedError
  end

  def set_user_item_visibilities
    raise NotImplementedError
  end

  def set_user_item_visibility
    @user_item_visibility = policy_scope(UserItemVisibility).find(params[:id])
  end

  def user_item_visibility_params
    params.require(:user_item_visibility).permit(:user_item_type, :user_item_id, :visible)
  end
end
