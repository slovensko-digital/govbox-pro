module Common
  class BadgeComponent < ViewComponent::Base
    def initialize(label="", color=nil, icon=nil, classes="")
      @label = label
      @classes = classes
      @color = color || "gray"
      @icon = icon
    end
  end
end
