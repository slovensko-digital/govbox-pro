module TagsAssignment
  class Component < ViewComponent::Base
    LIST_FRAME = "tags-assignment-list"
    DIFF_FRAME = "tags-assignment-diff"
    ACTIONS_FRAME = "tags-assignment-actions"
    SEARCH_FIELD_FRAME = "tags-assignment-search-field"

    def initialize(message_thread:, tags_changes:, tags_filter:)
      @message_thread = message_thread
      @tags_changes = tags_changes
      @tags_filter = tags_filter
    end
  end
end
