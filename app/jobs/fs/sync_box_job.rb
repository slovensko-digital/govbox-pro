module Fs
  class SyncBoxJob < ApplicationJob
    def perform(box, from: Date.today - 1.week, to: Date.tomorrow)
      raise unless box.is_a?(Fs::Box)
      return unless box.syncable?

      box.messages.outbox.not_drafts.find_each do |outbox_message|
        DownloadSentMessageJob.perform_later(outbox_message.metadata['fs_message_id'], box: outbox_message.box) if (from..to).cover?(outbox_message.delivered_at)
        DownloadSentMessageRelatedMessagesJob.perform_later(outbox_message, from: from, to: to)
      end
    end
  end
end
