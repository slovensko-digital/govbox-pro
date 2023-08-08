class MessageDraft < Message
  def self.create_from_message(message)
    MessageDraft.create!(
      uuid: SecureRandom.uuid,
      thread: message.thread,
      sender_name: message.recipient_name,
      recipient_name: message.sender_name,
      read: true,
      delivered_at: Time.now,
      metadata: {
        "status": "created",
        "correlation_id": message.metadata["correlation_id"],
        "reference_id": message.uuid,
        "original_message_id": message.id,
        "recipient_uri": message.metadata["sender_uri"],
      }
    )
  end

  def import
    Drafts::Import.find(metadata["import_id"]) if metadata["import_id"]
  end

  def submittable?
    title.present? && metadata["message_body"].present? && not_yet_submitted?
  end

  def not_yet_submitted?
    metadata["status"] == "created"
  end

  def being_submitted?
    metadata["status"] == "being_submitted"
  end

  def submitted?
    metadata["status"] == "submitted"
  end

  def original_message
    Message.find(metadata["original_message_id"])
  end
end
