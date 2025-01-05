class Admin::FeatureFlags::FeatureFlagsListRowComponent < ViewComponent::Base
  def initialize(flag, enabled_features)
    @feature_flag = flag
    @enabled = enabled_features.include?(flag)
  end
end
