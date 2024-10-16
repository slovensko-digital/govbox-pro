class Fs::DownloadSentMessageJob < ApplicationJob
  def perform(fs_message_id, box:, fs_client: FsEnvironment.fs_client)
    fs_api = fs_client.api(api_connection: box.api_connection, box: box)

    raw_message = fs_api.fetch_sent_message(fs_message_id)

    Fs::Message.create_outbox_message_with_thread!(raw_message, box: box)
  end
end
