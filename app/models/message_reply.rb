class MessageReply < Message
  def self.create_from_message(message)
    MessageReply.create!(
      uuid: SecureRandom.uuid,
      thread: message.thread,
      sender_name: message.recipient_name,
      recipient_name: message.sender_name,
      read: true,
      delivered_at: Time.now,
      metadata: {
        "recipient_uri": message.metadata["sender_uri"],
        "correlation_id": message.metadata["correlation_id"],
        "reference_id": message.uuid,
        "original_message_id": message.id,
      }
    )
  end

  def original_message
    Message.find(metadata["original_message_id"])
  end
end
