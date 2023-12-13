class ReindexAndNotifyFilterSubscriptionsJob < ApplicationJob
  queue_as :default

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

  def perform(thread_id)
    thread = MessageThread.find_by(id: thread_id)

    return unless thread

    Searchable::Indexer.index_message_thread(thread)
    
    thread.tenant.filter_subscriptions.find_each do |subscription|
      NotifyFilterSubscriptionJob.perform_later(subscription)
    end
  end
end
