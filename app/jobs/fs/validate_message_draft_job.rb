class Fs::ValidateMessageDraftJob < ApplicationJob
  include DiscardOnDeserializationError

  def perform(message_draft, fs_client: FsEnvironment.fs_client)
    message_draft.metadata['status'] = 'being_validated'
    message_draft.save

    response = fs_client.api(box: message_draft.thread.box).post_validation(
      message_draft.form.identifier,
      Base64.strict_encode64(message_draft.form_object.content)
    )

    unless response[:status] == 202
      mark_message_draft_invalid(message_draft)
      raise RuntimeError.new("Response status is not 202. Message #{response[:body][:errors]}")
    end

    Fs::ValidateMessageDraftStatusJob.perform_later(message_draft, response[:headers][:location])
  end

  private

  def mark_message_draft_invalid(message_draft)
    message_draft.metadata[:status] = 'invalid'
    message_draft.add_cascading_tag(message_draft.tenant.submission_error_tag)
  end
end
