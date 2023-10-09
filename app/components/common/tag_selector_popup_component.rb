module Common
  class TagSelectorPopupComponent < ViewComponent::Base
    def initialize(message_thread, search_available_tags, name_search)
      @message_thread = message_thread
      @tags = search_available_tags
      @name_search = name_search
    end
  end
end
