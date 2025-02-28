class MessageThreadHeaderComponent < ViewComponent::Base
  def initialize(message_thread, thread_tags, non_quick_thread_tags: [], quick_tags: [], quick_tags_changes: nil)
    @message_thread = message_thread
    @thread_tags = thread_tags
    @non_quick_thread_tags = non_quick_thread_tags
    @quick_tags = quick_tags
    @quick_tags_changes = quick_tags_changes
  end
end
