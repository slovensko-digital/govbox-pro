module Fs
  class DownloadSentMessageJob < ApplicationJob
    def perform(fs_message_id, message_draft:, fs_client: FsEnvironment.fs_client)
      raise unless message_draft.box.is_a?(Fs::Box)
      return unless message_draft.box.syncable?

      return if message_draft.box.messages.not_drafts.where("messages.metadata ->> 'fs_message_id' = ?", fs_message_id).any?

      ActiveRecord::Base.transaction do
        fs_api = fs_client.api(api_connection: Fs::Message.find_api_connection_for_outbox_message(message_draft), box: message_draft.box)

        raw_message = fs_api.fetch_sent_message(fs_message_id)

        message = Fs::Message.create_outbox_message_with_thread!(raw_message, box: message_draft.box)

        DownloadSentMessageRelatedMessagesJob.set(wait: 3.minutes).perform_later(message)
      end
    end
  end
end
