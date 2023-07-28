class Govbox::SubmitMessageDraftJob < ApplicationJob
  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(message_draft, upvs_client: UpvsEnvironment.upvs_client)
    reply_data = {
      message_id: message_draft.uuid,
      correlation_id: message_draft.draft.correlation_id,
      reference_id: message_draft.metadata["reference_id"],
      recipient_uri: message_draft.draft.recipient_uri,
      general_agenda: {
        subject: message_draft.title,
        body: message_draft.metadata["message_body"]
      },
      attachments: (message_attachments_data(message_draft) if message_draft.objects.any?)
    }.compact

    sktalk_api = upvs_client.api(message_draft.thread.folder.box).sktalk

    success, response_status = sktalk_api.receive_and_save_to_outbox(reply_data)

    raise StandardError, "Message reply submission failed!" unless success

    message_draft.metadata["status"] = "submitted"
    message_draft.save!

    Govbox::SyncBoxJob.set(wait: 3.minutes).perform_later(message_draft.thread.folder.box)
  end

  private

  def message_attachments_data(message_draft)
    message_draft.objects.map do |message_attachment|
      {
        id: uuid,
        name: message_attachment.name,
        signed: message_attachment.is_signed,
        encoding: "Base64",
        mime_type: Utils.detect_mime_type(entry_name: message_attachment.name),
        content: Base64.strict_encode64(message_attachment.message_object_datum.blob)
      }
    end
  end

  delegate :uuid, to: self
end
