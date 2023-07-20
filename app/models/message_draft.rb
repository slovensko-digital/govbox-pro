class MessageDraft < Message
  DRAFT_DEFAULT_POSP_ID = "App.GeneralAgenda"
  DRAFT_DEFAULT_POSP_VERSION = "1.9"
  DRAFT_DEFAULT_MESSAGE_TYPE = "App.GeneralAgenda"

  def self.create_from_message(message)
    draft_message = MessageDraft.create!(
      uuid: SecureRandom.uuid,
      thread: message.thread,
      sender_name: message.recipient_name,
      recipient_name: message.sender_name,
      read: true,
      delivered_at: Time.now,
      metadata: {
        "reference_id": message.uuid,
        "original_message_id": message.id,
      }
    )

    Draft.create!(
      box: message.thread.folder.box,
      recipient_uri: message.metadata["sender_uri"],
      posp_id: DRAFT_DEFAULT_POSP_ID,
      posp_version: DRAFT_DEFAULT_POSP_VERSION,
      message_type: DRAFT_DEFAULT_MESSAGE_TYPE,
      message_id: draft_message.uuid,
      correlation_id: message.metadata["correlation_id"],
    )

    draft_message
  end

  def original_message
    Message.find(metadata["original_message_id"])
  end

  def draft
    Draft.find_by(message_id: uuid)
  end
end
