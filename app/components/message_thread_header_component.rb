class MessageThreadHeaderComponent < ViewComponent::Base
  def initialize(message_thread, thread_tags)
    @message_thread = message_thread
    @thread_tags = thread_tags
  end
end
