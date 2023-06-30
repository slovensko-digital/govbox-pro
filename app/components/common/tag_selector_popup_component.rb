module Common
  class TagSelectorPopupComponent < ViewComponent::Base
    def initialize(object)
      @object = object
      @tags = Current.tenant.tags.where.not(id: object.tags.ids)
    end
  end
end
