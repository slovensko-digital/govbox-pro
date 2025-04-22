class Fs::ValidateMessageDraftJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  after_discard do
    GoodJob::Job.find_by(active_job_id: job.job_id).destroy
  end

  def perform(message_draft_id, fs_client: FsEnvironment.fs_client)
    message_draft.metadata['status'] = 'being_validated'
    message_draft.save

    response = fs_client.api(box: message_draft.thread.box).post_validation(
      message_draft.form.identifier,
      Base64.strict_encode64(message_draft.form_object.content)
    )

    raise "Response status is not 202. Message #{response[:body][:errors]}" unless response[:status] == 202

    Fs::ValidateMessageDraftStatusJob.perform_later(message_draft_id, response[:headers][:location])
  end
end
