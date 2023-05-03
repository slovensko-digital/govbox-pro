class Drafts::SubmitJob < ApplicationJob
  def perform(draft, sender: Upvs::GovboxApi)
    draft_data = {
      posp_id: draft.posp_id,
      posp_version: draft.posp_version,
      message_type: draft.message_type,
      message_id: draft.message_id,
      correlation_id: draft.correlation_id,
      recipient_uri: draft.recipient_uri,
      message_subject: draft.message_subject,
      objects: build_objects(draft)
    }

    sender = sender.new(draft.subject.sub).sktalk

    begin
      sender_response = sender.receive_and_save_to_outbox(draft_data)
      Draft.update!(status: "submitted") if sender_response
    rescue
      # TODO handle based on error code
      # TODO update draft status based on error code
      draft.update!(status: "submit_failed_unprocessable")
      raise "Draft #{draft.message_subject} failed!"
    end
  end

  private

  def build_objects(draft)
    objects = []
    draft.objects.each do |object|
      objects << {
        id: object.uuid,
        name: object.name,
        encoding: "Base64",
        signed: object.signed,
        mime_type: Utils.detect_mime_type(object),
        form: (object.form if object.form),
        content: Base64.strict_encode64(object.content.download)
      }.compact
    end

    objects
  end
end
