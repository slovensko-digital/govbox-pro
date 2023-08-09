class Drafts::SubmitJob < ApplicationJob
  def perform(draft, upvs_client: UpvsEnvironment.upvs_client)
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

    sktalk_api = upvs_client.api(folder.box).sktalk

    begin
      success, response_status = sktalk_api.receive_and_save_to_outbox(draft_data)
      if success
        draft.update!(status: "submitted")
      else
        handle_submit_fail(draft, response_status)
      end
    rescue
      draft.submit_failed_temporary!
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
        mime_type: Utils.detect_mime_type(entry_name: object.name, is_form: object.form?),
        form: (object.form if object.form),
        content: Base64.strict_encode64(object.content.download)
      }.compact
    end

    objects
  end

  def handle_submit_fail(draft, response_status)
    case response_status
    when 408
      # TODO
    when 422
      draft.submit_failed_unprocessable!
    else
      draft.submit_failed_temporary!
    end
  end
end
