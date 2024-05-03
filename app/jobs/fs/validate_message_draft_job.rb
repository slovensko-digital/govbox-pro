class Fs::ValidateMessageDraftJob < ApplicationJob
  def perform(message_draft, fs_client: FsEnvironment.fs_client)
    # TODO: This should become validate_message_draft_action.rb?
    response = fs_client.api.wait_for_result fs_client.api.post_validation(
      message_draft.metadata['fs_form_id'],
      message_draft.form_object.content  # TODO get content some other way
    )

    raise Error.new("Response status is not 200. Message #{response[:body][:errors]}") unless response[:status] == 200
    # TODO: Do something with this result
  end
end
