class Admin::FeatureFlags::FeatureFlagsListRowComponent < ViewComponent::Base
  def initialize(flag)
    @feature_flag = flag
  end
end
