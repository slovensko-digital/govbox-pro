module Common
  class TagSelectorPopupComponent < ViewComponent::Base
    def initialize(message_thread, search_available_tags, name_search)
      @message_thread = message_thread
      @tags = search_available_tags
      @name_search = name_search

      @new_tag = Current.tenant.tags.new(name: name_search)
      @new_tag.message_threads << @message_thread
    end
  end
end
