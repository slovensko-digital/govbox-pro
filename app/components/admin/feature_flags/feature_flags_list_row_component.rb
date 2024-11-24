class Admin::FeatureFlags::FeatureFlagsListRowComponent < ViewComponent::Base
  def initialize(flag, enabled_features)
    @feature_flag = flag
    @enabled = enabled_features.include?(flag)
    @features_changed = enabled_features.include?(flag) ? enabled_features - [flag] : enabled_features + [flag]
  end
end
