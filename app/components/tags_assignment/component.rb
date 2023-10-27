module TagsAssignment
  class Component < ViewComponent::Base
    LIST_FRAME = "tags-assignment-list"
    DIFF_FRAME = "tags-assignment-diff"
    ACTIONS_FRAME = "tags-assignment-actions"
    SEARCH_FIELD_FRAME = "tags-assignment-search-field"

    def initialize(message_thread:, all_tags:, tags_changes:, filtered_tag_ids:, name_search_query:)
      @message_thread = message_thread
      @all_tags = all_tags
      @tags_changes = tags_changes
      @filtered_tag_ids = filtered_tag_ids
      @name_search_query = name_search_query
    end
  end
end
