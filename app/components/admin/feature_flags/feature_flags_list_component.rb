class Admin::FeatureFlags::FeatureFlagsListComponent < ViewComponent::Base
  def initialize(feature_flags:)
    @feature_flags = feature_flags
  end
end
