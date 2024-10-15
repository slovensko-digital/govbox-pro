class Fs::DownloadSentMessageJob < ApplicationJob
  def perform(fs_message_id, box, fs_client: FsEnvironment.fs_client)
    fs_api = fs_client.api(api_connection: box.api_connection, box: box)

    raw_message = fs_api.fetch_sent_message(fs_message_id)
    message_draft = box.messages.where(type: 'Fs::MessageDraft').where("metadata ->> 'fs_message_id' = ?", fs_message_id).take

    Fs::Message.create_message_with_thread!(box, raw_message, associated_message_draft: message_draft)
  end
end
