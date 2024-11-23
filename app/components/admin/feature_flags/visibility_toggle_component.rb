class Admin::FeatureFlags::VisibilityToggleComponent < ViewComponent::Base
  def initialize(feature_flag)
    @feature_flag = feature_flag
  end
end
