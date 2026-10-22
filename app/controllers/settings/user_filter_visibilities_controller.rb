class Settings::UserFilterVisibilitiesController < ApplicationController
  before_action :set_preference, only: [:update, :move_higher, :move_lower]

  def create
    authorize UserFilterVisibility
    attributes = params.require(:user_filter_visibility).permit(:filter_id, :visible)
    Current.user.set_filter_visibility!(attributes.fetch(:filter_id), visible: ActiveModel::Type::Boolean.new.cast(attributes.fetch(:visible)))
    redirect_to filters_path
  end

  def update
    authorize @preference
    visible = ActiveModel::Type::Boolean.new.cast(params.require(:user_filter_visibility).fetch(:visible))
    Current.user.set_filter_visibility!(@preference.filter_id, visible: visible)
    redirect_to filters_path
  end

  def move_higher
    authorize @preference
    Current.user.move_filter!(@preference.filter_id, direction: :higher)
    redirect_to filters_path
  end

  def move_lower
    authorize @preference
    Current.user.move_filter!(@preference.filter_id, direction: :lower)
    redirect_to filters_path
  end

  private

  def set_preference
    @preference = Current.user.user_filter_visibilities.find(params[:id])
  end
end
