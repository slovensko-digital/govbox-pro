module TagsAssignment
  class ListComponent < ViewComponent::Base
    def initialize(tags_filter:, tags_assignments:, create_tag_path:)
      @tags_filter = tags_filter
      @tags_assignments = tags_assignments
      @locked_tags_assignments = { init: tags_assignments[:init], new: tags_assignments[:init] }
      @create_tag_path = create_tag_path
    end

    def manageable?(tag)
      @tags_filter.manageable_ids.include?(tag.id)
    end

    def checkbox_for(tag, manageable:)
      assignments = manageable ? @tags_assignments : @locked_tags_assignments
      RelationChanges::Checkbox.new(assignments: assignments, record_id: tag.id.to_s)
    end
  end
end
