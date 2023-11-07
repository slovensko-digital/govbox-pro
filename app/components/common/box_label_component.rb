module Common
  class BoxLabelComponent < ViewComponent::Base
    def initialize(box, classes = "", font_size_class = "text-sm")
      @box = box
      @classes = classes
      @font_size_class = font_size_class
    end
  end
end
