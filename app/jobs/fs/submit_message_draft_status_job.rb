class Fs::SubmitMessageDraftStatusJob < ApplicationJob
  def perform(message_draft, location_header, fs_client: FsEnvironment.fs_client)
    response = fs_client.api(box: message_draft.thread.box, api_connection: message_draft.find_api_connection_for_submission).get_location(location_header)

    if response[:headers][:retry_after]
      Fs::SubmitMessageDraftStatusJob.set(wait: response[:headers][:retry_after].to_i.seconds).perform_later(message_draft, location_header)
    else
      Fs::SubmitMessageDraftResultJob.perform_later(message_draft, response[:headers][:location])
    end
  end
end
