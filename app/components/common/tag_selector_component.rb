module Common
  class TagSelectorComponent < ViewComponent::Base
    def initialize(object, available_tags)
      @object = object
      @available_tags = available_tags
    end
  end
end
