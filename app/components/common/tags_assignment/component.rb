module Common
  module TagsAssignment
    class Component < ViewComponent::Base
      LIST_FRAME = "tags-assignment-list"
      CHANGES_FRAME = "tags-assignment-changes"
      ACTIONS_FRAME = "tags-assignment-actions"
      SEARCH_FIELD_FRAME = "tags-assignment-search-field"

      def initialize(message_thread:, all_tags:, init_tags_assignments:, new_tags_assignments:, diff:, filtered_tag_ids:, name_search:)
        @message_thread = message_thread
        @all_tags = all_tags
        @init_tags_assignments = init_tags_assignments
        @new_tags_assignments = new_tags_assignments
        @filtered_tag_ids = filtered_tag_ids
        @diff = diff
        @name_search = name_search
      end
    end
  end
end
