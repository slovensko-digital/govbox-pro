module Common
  class QuickTagsComponent < ViewComponent::Base
    def initialize(tags, tags_changes:, message_thread:)
      @message_thread = message_thread
      @tags = tags
      @tags_changes = tags_changes
    end
  end
end
