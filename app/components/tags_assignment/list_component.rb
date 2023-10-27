module TagsAssignment
  class ListComponent < ViewComponent::Base
    def initialize(message_thread:, all_tags:, filtered_tag_ids:, new_tags_assignments:, name_search_query:)
      @message_thread = message_thread
      @all_tags = all_tags
      @filtered_tag_ids = filtered_tag_ids
      @new_tags_assignments = new_tags_assignments
      @name_search_query = name_search_query
    end
  end
end
