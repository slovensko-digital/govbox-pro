module Fs
  class DownloadSentMessageJob < ApplicationJob
    def perform(fs_message_id, box:, fs_client: FsEnvironment.fs_client)
      raise unless box.is_a?(Fs::Box)
      return unless box.syncable?

      return if box.messages.where(type: [nil, 'Message']).where("metadata ->> 'fs_message_id' = ?", fs_message_id).any?

      begin
        fs_api = fs_client.api(api_connection: box.api_connection, box: box)

        raw_message = fs_api.fetch_sent_message(fs_message_id)

        message = Fs::Message.create_outbox_message_with_thread!(raw_message, box: box)

        DownloadSentMessageRelatedMessagesJob.set(wait: 3.minutes).perform_later(message)
      rescue Exception => e
        raise e
      end
    end
  end
end
