module TagsAssignment
  class ListComponent < ViewComponent::Base
    def initialize(tags_filter:, tags_assignments:, create_tag_path:)
      @tags_filter = tags_filter
      @tags_assignments = tags_assignments
      @create_tag_path = create_tag_path
    end
  end
end
