module Common
  class BoxLabelComponent < ViewComponent::Base
    def initialize(box, classes="", font_size_class="text-sm", padding_class="px-2 py-1")
      @classes = classes
      @font_size_class = font_size_class
      @padding_class = padding_class

      @color = box.color
      @label = box.short_name || box.name[0]
    end
  end
end
