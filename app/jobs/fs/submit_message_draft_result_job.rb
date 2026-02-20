class Fs::SubmitMessageDraftResultJob < ApplicationJob
  retry_on RuntimeError, attempts: 1 do |_job, _error|
    # no-op
  end

  def perform(message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box, api_connection: message_draft.find_api_connection_for_submission).get_location(location_header)

    if 200 == response[:status]
      message_draft.submitted!
      message_draft.metadata[:fs_message_id] = response[:body]['sent_message_id']
      message_draft.remove_cascading_tag(message_draft.tenant.submission_error_tag)
      message_draft.remove_cascading_tag(message_draft.tenant.problem_tag)
      message_draft.save

      ::Fs::DownloadSentMessageJob.perform_later(response[:body]['sent_message_id'], message_draft: message_draft)
    elsif [400, 422].include?(response[:status])
      message_draft.metadata[:status] = 'submit_fail'
      message_draft.add_cascading_tag(message_draft.tenant.submission_error_tag)
      message_draft.add_cascading_tag(message_draft.tenant.problem_tag)
      message_draft.save

      raise RuntimeError.new("Box #{message_draft.box.id}, Message #{message_draft.uuid}: #{response[:status]}")
    else
      raise RuntimeError.new("Unexpected response status: #{response[:status]}")
    end
  end
end
