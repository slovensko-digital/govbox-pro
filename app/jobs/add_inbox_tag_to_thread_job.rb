class AddInboxTagToThreadJob < ApplicationJob
  def perform(message_thread)
    message_thread.assign_tag(message_thread.tenant.inbox_tag) if message_thread.messages.any?{ |message| significant_inbox_message?(message) }
  end

  private

  def significant_inbox_message?(message)
    !message.outbox? && !Govbox::Message::INFORMATIONAL_MESSAGE_CLASSES.include?(message.metadata.dig('edesk_class'))
  end
end
