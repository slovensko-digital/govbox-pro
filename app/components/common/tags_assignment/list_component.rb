module Common
  module TagsAssignment
    class ListComponent < ViewComponent::Base
      def initialize(all_tags:, filtered_tag_ids:, new_tags_assignments:, name_search:)
        @all_tags = all_tags
        @filtered_tag_ids = filtered_tag_ids
        @new_tags_assignments = new_tags_assignments
        @name_search = name_search
      end
    end
  end
end
