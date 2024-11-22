class Admin::FeatureFlags::FeatureFlagComponent < ViewComponent::Base
  def initialize(feature_flag, classes: "", color: nil)
    @label = feature_flag.to_s
    @classes = classes
    @color = "gray"
    @icon = nil
  end
end
