class Admin::FeatureFlagsController < ApplicationController
  before_action :set_tenant

  def index
    authorize([:admin, :feature_flag])
    if params.include?(:labs)
      @feature_flags = @tenant.list_all_features
    else
      @feature_flags = @tenant.list_available_features
    end
    @enabled_features = @tenant.feature_flags
  end

  def update
    authorize([:admin, :feature_flag])
    if feature_flags_params[:enabled] == "true"
      @tenant.feature_flags << params[:id]
    else
      @tenant.feature_flags.delete(params[:id])
    end
    @tenant.save!
    redirect_to admin_tenant_feature_flags_path
  end

  private

  def set_tenant
    @tenant = policy_scope([:admin, :feature_flag]).find(params[:tenant_id])
  end

  def feature_flags_params
    params.require(:tenant).permit(:enabled)
  end
end
