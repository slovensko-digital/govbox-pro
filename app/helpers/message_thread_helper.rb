module MessageThreadHelper
  def self.show_recipient?(message_thread)
    message_thread.box.communication_to_multiple_subjects? && message_thread.is_outbox && message_thread.recipient.present?
  end

  def self.show_sender?(message_thread)
    !message_thread.box.communication_to_multiple_subjects? || (!message_thread.is_outbox && message_thread.sender.present?)
  end
end
