module Common
  class BoxLabelComponent < ViewComponent::Base
    def initialize(box, classes = "")
      @box = box
      @classes = classes
    end
  end
end
