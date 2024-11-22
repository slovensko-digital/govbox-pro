class Admin::FeatureFlags::VisibilityToggleComponent < ViewComponent::Base
  def initialize(feature_flag)
    @feature_flag = feature_flag
    @includes = Current.tenant.feature_flags.include?(feature_flag.to_s)
  end
end
