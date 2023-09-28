class MessageThreadHeaderComponent < ViewComponent::Base
  def initialize(message_thread, thread_tags_with_deletable_flag)
    @message_thread = message_thread
    @thread_tags_with_deletable_flag = thread_tags_with_deletable_flag
  end
end
