class Searchable::ReindexMessageThreadJob < ApplicationJob
  queue_as :default

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    # Maximum number of unfinished jobs to allow with the concurrency key
    # Can be an Integer or Lambda/Proc that is invoked in the context of the job
    total_limit: 1,

    key: -> { "Searchable::ReindexMessageThreadJob-#{arguments.first.try(:id)}" }
  )

  retry_on ::ApplicationRecord::FailedToAcquireLockError, wait: :exponentially_longer, attempts: Float::INFINITY
  discard_on ActiveJob::DeserializationError

  def perform(message_thread)
    return if message_thread.nil?

    ::Searchable::MessageThread.transaction do
      ::Searchable::MessageThread.with_advisory_lock!("mt_#{message_thread.id}", transaction: true, timeout_seconds: 10) do
        ::Searchable::MessageThread.index_record(message_thread)
      end
    end
  end
end
