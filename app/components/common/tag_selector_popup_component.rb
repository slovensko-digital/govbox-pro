module Common
  class TagSelectorPopupComponent < ViewComponent::Base
    def initialize(object)
      @object = object
      @tags = policy_scope(Tag).where.not(id: object.tags.ids).where(visible: true)
    end
  end
end
