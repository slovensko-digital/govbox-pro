class Searchable::ReindexMessageThreadJob < ApplicationJob
  queue_as :default

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    # Maximum number of unfinished jobs to allow with the concurrency key
    # Can be an Integer or Lambda/Proc that is invoked in the context of the job
    total_limit: 1,

    key: -> { "Searchable::ReindexMessageThreadJob-#{arguments.first.try(:id)}" }
  )

  discard_on ActiveJob::DeserializationError

  def perform(message_thread)
    return if message_thread.nil?

    ::Searchable::MessageThread.index_record(message_thread)
  end
end
