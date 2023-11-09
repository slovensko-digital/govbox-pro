module Common
  class BadgeComponent < ViewComponent::Base
    def initialize(label, classes="")
      @label = label
      @classes = classes
    end
  end
end
