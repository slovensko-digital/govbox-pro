class MessageThreadComponent < ViewComponent::Base
  def initialize(message_thread:, thread_tags:, thread_messages:)
    @message_thread = message_thread
    @thread_tags = thread_tags
    @thread_messages = thread_messages
  end
end
