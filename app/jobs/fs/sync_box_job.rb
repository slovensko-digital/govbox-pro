module Fs
  class SyncBoxJob < ApplicationJob
    def perform(box)
      raise unless box.is_a?(Fs::Box)
      return unless box.syncable?

      box.messages.outbox.find_each do |outbox_message|
        # TODO overit, ci to ma byt dnesny datum alebo az zajtrajsi
        Fs::DownloadSentMessageRelatedMessagesJob(outbox_message, from: Date.today - 1.week, to: Date.today)
      end
    end
  end
end
