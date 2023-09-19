module Common
  class TagSelectorPopupComponent < ViewComponent::Base
    def initialize(object, available_tags)
      @object = object
      @tags = available_tags
    end
  end
end
