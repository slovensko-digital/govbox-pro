class Searchable::ReindexMessageThreadJob < ApplicationJob
  queue_as :default

  retry_on ::ApplicationRecord::FailedToAcquireLockError, wait: :exponentially_longer, attempts: Float::INFINITY

  def perform(message_thread)
    ::Searchable::MessageThread.transaction do
      ::Searchable::MessageThread.with_advisory_lock!("mt_#{message_thread.id}", transaction: true, timeout_seconds: 10) do
        ::Searchable::MessageThread.index_record(message_thread)
      end
    end
  end
end
