module TagsAssignment
  class BulkListComponent < ViewComponent::Base
    def initialize(tags_filter:, tags_assignments:)
      @tags_filter = tags_filter
      @tags_assignments = tags_assignments
    end
  end
end
