module Fs
  class SyncBoxJob < ApplicationJob
    def perform(box, from: Date.today - 1.week, to: Date.tomorrow)
      raise unless box.is_a?(Fs::Box)
      return unless box.syncable?

      box.messages.outbox.except_drafts.find_each do |outbox_message|
        DownloadSentMessageRelatedMessagesJob.perform_later(outbox_message, from: from, to: to)
      end
    end
  end
end
