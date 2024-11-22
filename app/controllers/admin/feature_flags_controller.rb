class Admin::FeatureFlagsController < ApplicationController
  before_action :set_tenant, only: %i[update]

  def index
    # TODO: make feature flag policy
    authorize([:admin, User])
    @feature_flags = Current.tenant.list_features
  end

  def update
    authorize([:admin, User])
    @tenant.feature_flags = feature_flags_params["feature_flags"].split(",")
    @tenant.save!
    redirect_to admin_tenant_feature_flags_path
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:tenant_id])
  end

  def feature_flags_params
    params.require(:tenant).permit(:feature_flags)
  end
end
