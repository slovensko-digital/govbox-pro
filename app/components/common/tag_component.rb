module Common
  class TagComponent < ViewComponent::Base
    def initialize(label, classes="")
      @label = label
      @classes = classes
    end
  end
end
