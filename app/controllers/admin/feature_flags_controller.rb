class Admin::FeatureFlagsController < ApplicationController
  before_action :set_tenant

  def index
    authorize([:admin, :feature_flag])
    @feature_flags = @tenant.list_features
    @enabled_features = @tenant.feature_flags
  end

  def update
    authorize([:admin, :feature_flag])
    @tenant.feature_flags = feature_flags_params["feature_flags"].split(",")
    @tenant.save!
    redirect_to admin_tenant_feature_flags_path
  end

  private

  def set_tenant
    @tenant = policy_scope([:admin, :feature_flag]).find(params[:tenant_id])
  end

  def feature_flags_params
    params.require(:tenant).permit(:feature_flags)
  end
end
