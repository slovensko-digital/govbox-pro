module TagsAssignment
  class ListComponent < ViewComponent::Base
    def initialize(message_thread:, tags_filter:, new_tags_assignments:)
      @message_thread = message_thread
      @tags_filter = tags_filter
      @new_tags_assignments = new_tags_assignments
    end
  end
end
