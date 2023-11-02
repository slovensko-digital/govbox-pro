module Common
  class BadgeComponent < ViewComponent::Base
    def initialize(label)
      @label = label
    end
  end
end
