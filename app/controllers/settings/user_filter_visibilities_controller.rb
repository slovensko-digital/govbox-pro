class Settings::UserFilterVisibilitiesController < ApplicationController
  before_action :set_user_filter_visibility, only: [:update, :move_higher, :move_lower, :destroy]

  def index
    authorize UserFilterVisibility

    set_user_filter_visibilities
  end

  def create
    authorize UserFilterVisibility
    Current.user.user_filter_visibilities.create(user_filter_visibility_params).tap do |visibility|
      visibility.move_to_bottom
    end
    redirect_back fallback_location: request.referer
  end

  def update
    authorize @user_filter_visibility
    @user_filter_visibility.update(user_filter_visibility_params)
    redirect_back fallback_location: request.referer
  end

  def move_higher
    authorize @user_filter_visibility
    @user_filter_visibility.move_higher
    redirect_back fallback_location: request.referer
  end

  def move_lower
    authorize @user_filter_visibility
    @user_filter_visibility.move_lower
    redirect_back fallback_location: request.referer
  end

  def destroy
    authorize @user_filter_visibility
    @user_filter_visibility.destroy
    redirect_back fallback_location: request.referer
  end

  private

  def set_user_filter_visibilities
    @user_filter_visibilities = Current.user.build_filter_visibilities!
  end

  def set_user_filter_visibility
    @user_filter_visibility = policy_scope(UserFilterVisibility).find(params[:id])
  end

  def user_filter_visibility_params
    params.require(:user_filter_visibility).permit(:filter_id, :visible)
  end
end
