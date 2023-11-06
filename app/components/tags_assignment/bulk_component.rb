module TagsAssignment
  class BulkComponent < ViewComponent::Base
    LIST_FRAME = "tags-assignment-list"
    DIFF_FRAME = "tags-assignment-diff"
    ACTIONS_FRAME = "tags-assignment-actions"
    SEARCH_FIELD_FRAME = "tags-assignment-search-field"

    def initialize(message_threads:, tags_changes:, tags_filter:)
      @message_threads = message_threads
      @tags_changes = tags_changes
      @tags_filter = tags_filter
    end
  end
end
