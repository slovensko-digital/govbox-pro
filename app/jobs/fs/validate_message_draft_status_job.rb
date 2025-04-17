class Fs::ValidateMessageDraftStatusJob < ApplicationJob
  def perform(message_draft_id, location_header, fs_client: FsEnvironment.fs_client)
    message_draft = Message.find_by(id: message_draft_id)
    return unless message_draft

    response = fs_client.api(box: message_draft.thread.box).get_location(location_header)

    if response[:headers][:retry_after]
      Fs::ValidateMessageDraftStatusJob.set(wait: response[:headers][:retry_after].to_i.seconds).perform_later(message_draft_id, location_header)
    else
      Fs::ValidateMessageDraftResultJob.perform_later(message_draft_id, response[:headers][:location])
    end
  end
end
