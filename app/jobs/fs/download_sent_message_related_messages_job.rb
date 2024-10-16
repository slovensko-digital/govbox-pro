class Fs::DownloadSentMessageRelatedMessagesJob < ApplicationJob
  def perform(outbox_message, fs_client: FsEnvironment.fs_client)
    fs_api = fs_client.api(api_connection: outbox_message.box.api_connection, box: outbox_message.box)

    received_messages = fs_api.fetch_received_messages(sent_message_id: outbox_message.metadata['fs_message_id'])

    received_messages['messages'].each do |received_message|
      ::Fs::DownloadReceivedMessageJob.perform_later(received_message['message_id'], box: outbox_message.box)
    end
  end
end
