module Common
  class TagComponent < ViewComponent::Base
    def initialize(tag, classes="", color: nil)
      @label = tag.name || tag.external_name
      @classes = classes
      @color = tag.color || "gray"
      @icon = tag.icon.presence || (tag.gives_access? ? "key" : nil)
    end
  end
end
