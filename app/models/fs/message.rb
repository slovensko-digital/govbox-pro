class Fs::Message
  FS_SUBJECT_NAME = 'Finančná správa'

  def self.create_inbox_message_with_thread!(raw_message, box:)
    message = nil
    associated_outbox_message = box.messages.where("metadata ->> 'fs_message_id' = ?", raw_message['sent_message_id']).take

    MessageThread.with_advisory_lock!(associated_outbox_message.metadata['correlation_id'], transaction: true, timeout_seconds: 10) do
      message = create_inbox_message(raw_message)

      message.thread = associated_outbox_message.thread

      message.save!

      create_message_objects(message, raw_message)
      update_html_visualization(message)

      MessageObject.mark_message_objects_externally_signed(message.objects)
    end

    EventBus.publish(:message_thread_created, message.thread) if message.thread.previously_new_record?
    EventBus.publish(:message_created, message)
  end

  def self.create_outbox_message_with_thread!(raw_message, box:)
    message = nil
    associated_message_draft = box.messages.where(type: 'Fs::MessageDraft').where("metadata ->> 'fs_message_id' = ?", raw_message['message_id']).take

    merge_identifier = (associated_message_draft.metadata['correlation_id'] if associated_message_draft) || SecureRandom.uuid

    MessageThread.with_advisory_lock!(merge_identifier, transaction: true, timeout_seconds: 10) do
      message = create_outbox_message(raw_message, associated_message_draft: associated_message_draft)

      message.thread = associated_message_draft&.thread
      message.thread ||= box.message_threads.find_or_create_by_merge_uuid!(
        box: box,
        merge_uuid: merge_identifier,
        title: message.title,
        delivered_at: message.delivered_at
      )

      message.save!

      create_message_objects(message, raw_message)
      update_html_visualization(message)

      if associated_message_draft
        message.copy_tags_from_draft(associated_message_draft)
        associated_message_draft.destroy
      end

      MessageObject.mark_message_objects_externally_signed(message.objects)
    end

    EventBus.publish(:message_thread_created, message.thread) if message.thread.previously_new_record?
    EventBus.publish(:message_created, message)

    message
  end

  private

  def self.create_inbox_message(raw_message)
    Message.create(
      uuid: raw_message.dig('message_container', 'message_id'),
      title: raw_message['message_type_name'],
      sender_name: FS_SUBJECT_NAME,
      recipient_name: raw_message['subject'],
      delivered_at: Time.zone.parse(raw_message['created_at']),
      replyable: false,
      collapsed: collapsed?,
      outbox: false,
      metadata: {
        "fs_message_id": raw_message['message_id'],
        "fs_sent_message_id": raw_message['sent_message_id'],
        "fs_status": raw_message['status'],
        "fs_submitting_subject": raw_message['submitting_subject'],
        "fs_submission_status": raw_message['submission_status'],
        "fs_message_type": raw_message.dig('message_container', 'message_type'),
        "fs_submission_type_id": raw_message['submission_type_id'], # TODO kde pouzit? asi napr. pri vytvarani nazvu suboru pri exporte
        "fs_submission_created_at": Time.zone.parse(raw_message['submission_created_at']),
        "fs_period": raw_message['period'],
        "fs_dismissal_reason": raw_message['dismissal_reason'],
        "fs_other_attributes": raw_message['other_attributes'],
        "dic": raw_message['dic']
      },
    )
  end

  def self.create_outbox_message(raw_message, associated_message_draft: nil)
    Message.create(
      uuid: raw_message.dig('message_container', 'message_id'),
      title: raw_message['submission_type_name'],
      sender_name: raw_message['subject'],
      recipient_name: FS_SUBJECT_NAME,
      delivered_at: Time.zone.parse(raw_message['created_at']),
      replyable: false,
      collapsed: collapsed?,
      outbox: true,
      metadata: {
        "fs_form_id": (associated_message_draft.metadata['fs_form_id'] if associated_message_draft) || Fs::Form.find_by(submission_type_identifier: raw_message['submission_type_id'])&.id,
        "fs_message_id": raw_message['message_id'],
        "fs_status": raw_message['status'],
        "fs_submitting_subject": raw_message['submitting_subject'],
        "fs_period": raw_message['period'],
        "fs_dismissal_reason": raw_message['dismissal_reason'],
        "fs_other_attributes": raw_message['other_attributes'],
        "dic": raw_message['dic']
      },
    )
  end

  def self.create_message_objects(message, raw_message)
    raw_message.dig('message_container', 'objects').each do |raw_object|
      tags = raw_object["signed"] ? [message.thread.box.tenant.signed_externally_tag!] : []

      message_object = message.objects.create!(
        uuid: raw_object["id"],
        is_signed: raw_object["signed"],
        mimetype: raw_object["mime_type"],
        name: raw_object["name"],
        object_type: raw_object["class"],
        tags: tags
      )

      if raw_object["encoding"] == "Base64"
        message_object_content = Base64.decode64(raw_object["content"])
      else
        message_object_content = raw_object["content"]
      end

      MessageObjectDatum.create!(
        blob: message_object_content,
        message_object: message_object
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
    # TODO urcit podmienky: odoslana sprava s potvrdenkou by mohla byt collapsed
    false
  end
end
