class MessageThreadHistoryLogComponent < ViewComponent::Base
  def initialize(message_thread:, thread_tags_with_deletable_flag:, thread_messages:)
    @message_thread = message_thread
    @thread_tags_with_deletable_flag = thread_tags_with_deletable_flag
    @thread_messages = thread_messages
  end
end
