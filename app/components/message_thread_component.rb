class MessageThreadComponent < ViewComponent::Base
  def initialize(message_thread:, thread_tags:, thread_messages:, thread_last_message_draft_id:, user_is_signer:)
    @message_thread = message_thread
    @thread_tags = thread_tags
    @thread_messages = thread_messages
    @thread_last_message_draft_id = thread_last_message_draft_id
    @user_is_signer = user_is_signer
  end
end
