class Fs::Message
  FS_SUBJECT_NAME = 'Finančná správa'

  def self.create_inbox_message_with_thread!(raw_message, box:)
    message = nil
    associated_outbox_message = box.messages.where("metadata ->> 'fs_message_id' = ?", raw_message['sent_message_id']).take

    MessageThread.with_advisory_lock!(associated_outbox_message.metadata['correlation_id'], transaction: true, timeout_seconds: 10) do
      message = create_inbox_message(raw_message)

      message.thread = associated_outbox_message.thread

      message.save!
    end

    create_message_objects(message, raw_message)
    update_html_visualization(message)

    EventBus.publish(:message_created, message)
  end

  def self.create_outbox_message_with_thread!(raw_message, box:)
    message = nil
    associated_message_draft = box.messages.where(type: 'Fs::MessageDraft').where("metadata ->> 'fs_message_id' = ?", raw_message['message_id']).take

    merge_identifier = (associated_message_draft.metadata['correlation_id'] if associated_message_draft) || SecureRandom.uuid

    MessageThread.with_advisory_lock!(merge_identifier, transaction: true, timeout_seconds: 10) do
      message = create_outbox_message(raw_message)

      message.thread = box.message_threads.find_or_create_by_merge_uuid!(
        box: box,
        merge_uuid: merge_identifier,
        title: message.title,
        delivered_at: message.delivered_at
      )

      associated_message_draft.destroy if associated_message_draft

      message.save!
    end

    create_message_objects(message, raw_message)
    update_html_visualization(message)

    EventBus.publish(:message_created, message)
  end

  private

  def self.create_inbox_message(raw_message)
    Message.create(
      uuid: SecureRandom.uuid,
      title: raw_message['message_type_name'],
      recipient_name: FS_SUBJECT_NAME,
      sender_name: raw_message['subject'],
      delivered_at: Time.parse(raw_message['created_at']),
      replyable: false,
      collapsed: collapsed?,
      outbox: false,
      metadata: {
        # TODO: Toto je problem pri prijatych spravach, je tam typ podania (outbox message)
        "fs_form_id": nil,
        "fs_message_id": raw_message['message_id'],
        "fs_status": raw_message['status'],
        "fs_submission_status": raw_message['submission_status'],
        "dic": raw_message['dic']
      },
    )
  end

  def self.create_outbox_message(raw_message, associated_message_draft: nil)
    Message.create(
      uuid: (associated_message_draft.uuid if associated_message_draft) || SecureRandom.uuid,
      title: raw_message['submission_type_name'],
      sender_name: raw_message['subject'],
      recipient_name: FS_SUBJECT_NAME,
      delivered_at: Time.parse(raw_message['created_at']),
      replyable: false,
      collapsed: collapsed?,
      outbox: true,
      metadata: {
        "fs_form_id": (associated_message_draft.metadata['fs_form_id'] if associated_message_draft) || Fs::Form.where("identifier LIKE '#{raw_message['submission_type_id']}_%'")&.take&.id,
        "fs_message_id": raw_message['message_id'],
        "fs_status": raw_message['status'],
        "dic": raw_message['dic']
      },
    )
  end

  def self.create_message_objects(message, raw_message)
    raw_message.dig('message_container', 'objects').each do |raw_object|
      tags = raw_object["signed"] ? [message.thread.box.tenant.signed_externally_tag!] : []

      message_object = message.objects.create!(
        # uuid: raw_object["id"], TODO uncomment when GO-130 is closed
        is_signed: raw_object["is_signed"],
        mimetype: raw_object["mime_type"],
        name: raw_object["name"],
        object_type: raw_object["class"],
        tags: tags
      )

      if raw_object["encoding"] == "Base64"
        message_object_content = Base64.decode64(raw_object["data"])
      else
        message_object_content = raw_object["xml_data"]
      end

      MessageObjectDatum.create!(
        blob: message_object_content,
        message_object_id: message_object.id
      )
    end
  end

  def self.update_html_visualization(message)
    message.update(
      html_visualization: Fs::MessageHelper.build_html_visualization(message)
    )

    message.form_object&.update(
      visualizable: message.html_visualization.present?
    )
  end

  def self.collapsed?
    # TODO odoslana sprava s potvrdenkou by mohla byt collapsed
    false
  end
end
