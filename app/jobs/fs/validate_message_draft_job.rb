class Fs::ValidateMessageDraftJob < ApplicationJob
  def perform(message_draft, fs_client: FsEnvironment.fs_client)
    message_draft.metadata['status'] = 'being_validated'
    message_draft.save

    response = fs_client.api(box: message_draft.thread.box).post_validation(
      message_draft.form.identifier,
      Base64.strict_encode64(message_draft.form_object.content)
    )

    raise RuntimeError.new("Response status is not 202. Message #{response[:body][:errors]}") unless response[:status] == 202

    Fs::ValidateMessageDraftStatusJob.perform_later(message_draft, response[:headers][:location])
  end
end
