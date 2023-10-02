module Common
  class TagSelectorPopupComponent < ViewComponent::Base
    def initialize(object, available_tags, name_search)
      @object = object
      @tags = available_tags
      @name_search = name_search
      if @object.class == MessageThread
        @new_tag = Current.tenant.tags.new(name: name_search)
        @new_tag.message_threads << @object
      elsif @object.class == Message
        @new_tag = Current.tenant.tags.new(name: name_search)
        @new_tag.messages << @object
      end
    end
  end
end
