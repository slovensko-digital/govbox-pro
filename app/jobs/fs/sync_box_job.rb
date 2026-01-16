module Fs
  class SyncBoxJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_limit: 2
    )

    def perform(box, api_connection:, from: Date.yesterday, to: Date.tomorrow, fs_client: FsEnvironment.fs_client, batch_size: 25)
      raise unless box.is_a?(Fs::Box)
      return unless box.syncable?
      return unless box.active?

      fs_api = fs_client.api(api_connection: api_connection, box: box)

      0.step do |k|
        received_messages = fs_api.fetch_received_messages(page: k + 1, count: batch_size, from: from, to: to)

        if received_messages['messages'].none?
          received_messages = fs_api.fetch_received_messages(page: k + 1, count: batch_size, from: from, to: to, obo: fs_api.obo_without_delegate)
        end

        received_messages['messages'].each do |received_message|
          related_outbox_message = box.messages.not_drafts.where("messages.metadata ->> 'fs_message_id' = ?", received_message['sent_message_id']).first

          next unless related_outbox_message

          ::Fs::DownloadReceivedMessageJob.perform_later(received_message['message_id'], box: box)
        end

        break if received_messages['messages'].size < batch_size
      end
    end
  end
end
