class MessageThreadComponent < ViewComponent::Base
  def initialize(message_thread:, thread_tags_with_deletable_flag:, thread_messages:, flash:)
    @message_thread = message_thread
    @thread_tags_with_deletable_flag = thread_tags_with_deletable_flag
    @thread_messages = thread_messages
    @flash = flash
  end
end
