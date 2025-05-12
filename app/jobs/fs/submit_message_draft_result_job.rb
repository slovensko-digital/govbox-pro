class Fs::SubmitMessageDraftResultJob < ApplicationJob
  def perform(message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box).get_location(location_header)

    if 200 == response[:status]
      message_draft.submitted!
      message_draft.metadata[:fs_message_id] = response[:body]['sent_message_id']
      message_draft.remove_cascading_tag(message_draft.tenant.submission_error_tag)
      message_draft.save

      ::Fs::DownloadSentMessageJob.perform_later(response[:body]['sent_message_id'], box: message_draft.box)
    elsif [400, 422].include?(response[:status])
      message_draft.metadata[:status] = 'submit_fail'
      message_draft.add_cascading_tag(message_draft.tenant.submission_error_tag)
      message_draft.save
    else
      raise RuntimeError.new("Unexpected response status: #{response[:status]}")
    end
  end
end
