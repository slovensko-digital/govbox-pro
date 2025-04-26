class Fs::ValidateMessageDraftStatusJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  after_discard do |job, exception|
    return unless exception.is_a?(ActiveJob::DeserializationError)

    Rails.logger.warn("Deleting job #{job.job_id} due to #{exception.message}")
    GoodJob::Job.find_by(active_job_id: job.job_id).destroy
  end

  def perform(message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box).get_location(location_header)

    if response[:headers][:retry_after]
      Fs::ValidateMessageDraftStatusJob.set(wait: response[:headers][:retry_after].to_i.seconds).perform_later(message_draft, location_header)
    else
      Fs::ValidateMessageDraftResultJob.perform_later(message_draft, response[:headers][:location])
    end
  end
end
