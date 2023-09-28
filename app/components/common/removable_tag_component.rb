module Common
  class RemovableTagComponent < ViewComponent::Base
    def initialize(object_tag)
      @object_tag = object_tag
      @tag = @object_tag.tag
    end
  end
end
