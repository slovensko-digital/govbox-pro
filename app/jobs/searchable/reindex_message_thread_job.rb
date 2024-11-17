class Searchable::ReindexMessageThreadJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    # Maximum number of unfinished jobs to allow with the concurrency key
    # Can be an Integer or Lambda/Proc that is invoked in the context of the job
    total_limit: 2,

    # Maximum number of jobs with the concurrency key to be
    # concurrently performed (excludes enqueued jobs)
    # Can be an Integer or Lambda/Proc that is invoked in the context of the job
    perform_limit: 1,

    key: -> { "Searchable::ReindexMessageThreadJob-#{arguments.first}" }
  )

  def perform(message_thread_id)
    message_thread = ::MessageThread.find_by_id(message_thread_id)

    return if message_thread.nil?

    ::Searchable::Indexer.index_message_thread(message_thread)
  end
end
