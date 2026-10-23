class ReindexAndNotifyFilterSubscriptionsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  include DiscardOnDeserializationError

  good_job_concurrency_rule(
    label: -> { "ReindexAndNotifyFilterSubscriptionsJob-#{arguments.first}" },
    apply_label: true,
    total_limit: 2,
    perform_limit: 1
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
    Searchable::MessageThread.with_tag_id(tag_id).find_each { |s| perform_later(s.message_thread_id) }
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
