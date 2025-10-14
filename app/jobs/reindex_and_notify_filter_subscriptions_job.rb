class ReindexAndNotifyFilterSubscriptionsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    # Maximum number of unfinished jobs to allow with the concurrency key
    # Can be an Integer or Lambda/Proc that is invoked in the context of the job
    total_limit: 2,

    # Maximum number of jobs with the concurrency key to be
    # concurrently performed (excludes enqueued jobs)
    # Can be an Integer or Lambda/Proc that is invoked in the context of the job
    perform_limit: 1,

    key: -> { "ReindexAndNotifyFilterSubscriptionsJob-#{arguments.first}" }
  )

  def perform(thread_id, author = nil)
    thread = MessageThread.find_by(id: thread_id)

    return unless thread

    MessageThread.transaction do
      candidates = thread.tenant.filter_subscriptions
      candidates = candidates.where.not(user: author) if author

      matching_before = matching_subscriptions(candidates, thread)
      update_snapshot(thread)
      matching_after = matching_subscriptions(candidates, thread)

      matching_after.each do |s|
        NotifyFilterSubscriptionJob.perform_later(s, thread, matching_before.include?(s))
      end
    end
  end

  def self.perform_later_for_tag_id(tag_id)
    Searchable::MessageThread.with_tag_id(tag_id).find_each { |s| perform_later(s.message_thread) }
  end

  private

  def matching_subscriptions(candidates, thread)
    candidates.select do |subscription|
      Searchable::MessageThread
        .matching(subscription)
        .where(message_thread: thread)
        .exists?
    end
  end

  def update_snapshot(thread)
    # using fulltext index as snapshotting engine
    Searchable::Indexer.index_message_thread(thread)
  end
end
