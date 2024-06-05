class Fs::SubmitMessageDraftJob < ApplicationJob
  def perform(message_draft, fs_client: FsEnvironment.fs_client)
    raise "Invalid message!" unless message_draft.valid?(:validate_data)

    response = fs_client.api(box: message_draft.thread.box).post_submission(
      message_draft.form.identifier,
      Base64.strict_encode64(message_draft.form_object.content),
      message_draft.form_object.is_signed
    )

    raise RuntimeError.new("Response status is not 202. Message #{response[:body][:errors]}") unless response[:status] == 202

    Fs::SubmitMessageDraftStatusJob.perform_later(message_draft, response[:headers][:location])
  end
end
