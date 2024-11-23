class Admin::FeatureFlags::FeatureFlagToggleComponent < ViewComponent::Base
  def initialize(feature_flag)
    @feature_flag = feature_flag
  end
end
