class Fs::DownloadSentMessageRelatedMessagesJob < ApplicationJob
  def perform(outbox_message, fs_client: FsEnvironment.fs_client, batch_size: 25)
    fs_api = fs_client.api(api_connection: outbox_message.box.api_connection, box: outbox_message.box)

    0.step do |k|
      received_messages = fs_api.fetch_received_messages(sent_message_id: outbox_message.metadata['fs_message_id'], page: k + 1, count: batch_size)

      received_messages['messages'].each do |received_message|
        ::Fs::DownloadReceivedMessageJob.perform_later(received_message['message_id'], box: outbox_message.box)
      end

      break if received_messages['messages'].size < batch_size
    end
  end
end
