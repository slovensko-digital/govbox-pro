class MessageThreadComponent < ViewComponent::Base
  def initialize(message_thread:, thread_tags_with_deletable_flag:, thread_messages:, message_thread_note:, notice:)
    @message_thread = message_thread
    @thread_tags_with_deletable_flag = thread_tags_with_deletable_flag
    @thread_messages = thread_messages
    @message_thread_note = message_thread_note
    @notice = notice
  end
end
