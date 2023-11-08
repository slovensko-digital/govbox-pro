module TagsAssignment
  class BulkComponent < ViewComponent::Base
    def initialize(message_threads:, tags_changes:, tags_filter:)
      @message_threads = message_threads
      @tags_changes = tags_changes
      @tags_filter = tags_filter
    end
  end
end
