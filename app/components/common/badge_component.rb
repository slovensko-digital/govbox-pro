module Common
  class BadgeComponent < ViewComponent::Base
    def initialize(label, classes="", span_classes="")
      @label = label
      @classes = classes
      @span_classes = span_classes
    end
  end
end
