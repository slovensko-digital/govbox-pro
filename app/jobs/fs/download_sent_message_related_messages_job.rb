module Fs
  class DownloadSentMessageRelatedMessagesJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_throttle: [250, 1.minute]
    )

    class MissingRelatedMessagesError < StandardError
    end

    retry_on MissingRelatedMessagesError, attempts: 1 do |_job, _error|
      # no-op
    end

    def perform(outbox_message, from: nil, to: nil, fs_client: FsEnvironment.fs_client, batch_size: 25)
      raise unless outbox_message.box.is_a?(Fs::Box)
      return unless outbox_message.box.syncable?

      fs_api = fs_client.api(api_connection: outbox_message.box.api_connection, box: outbox_message.box)

      0.step do |k|
        received_messages = fs_api.fetch_received_messages(sent_message_id: outbox_message.metadata['fs_message_id'], page: k + 1, count: batch_size, from: from, to: to)

        if received_messages['messages'].none?
          received_messages = fs_api.fetch_received_messages(sent_message_id: outbox_message.metadata['fs_message_id'], page: k + 1, count: batch_size, from: from, to: to, obo: fs_api.obo_without_delegate)
        end

        raise MissingRelatedMessagesError if outbox_message.thread.messages.excluding(outbox_message).none? && received_messages['messages'].none? && outbox_message.delivered_at < 1.hour.ago

        received_messages['messages'].each do |received_message|
          ::Fs::DownloadReceivedMessageJob.perform_later(received_message['message_id'], box: outbox_message.box)
        end

        break if received_messages['messages'].size < batch_size
      end
    end
  end
end
