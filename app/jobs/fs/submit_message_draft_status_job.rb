class Fs::SubmitMessageDraftStatusJob < ApplicationJob
  def perform(message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box).get_location(location_header)

    if response[:headers][:retry_after]
      Fs::SubmitMessageDraftStatusJob.set(wait: response[:headers][:retry_after].to_i.seconds, queue: self.queue_name).perform_later(message_draft, location_header)
    else
      Fs::SubmitMessageDraftResultJob.set(queue: self.queue_name).perform_later(message_draft, response[:headers][:location])
    end
  end
end
