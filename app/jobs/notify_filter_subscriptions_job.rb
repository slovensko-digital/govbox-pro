class NotifyFilterSubscriptionsJob < ApplicationJob
  queue_as :default

  def perform(event, thing)
    case event
    when :message_created
      perform_with_thread(event, thing, thing.thread)
    else
      raise NotImplementedError
    end
  end

  private

  def perform_with_thread(event, thing, thread)
    candidates = thread.tenant.filter_subscriptions.where('? = ANY(events)', event).to_a

    before = matching_subscriptions(candidates, thread)
    update_snapshot(thread)
    after = matching_subscriptions(candidates, thread)

    changes = after - before
    changes.each do |s|
      s.create_notification!(event, thing)
    end
  end

  def matching_subscriptions(candidates, thing)
    candidates.select do |s|
      out = MessageThreadCollection.all(
        scope: Pundit.policy_scope(s.user, MessageThread).where(id: thing.id),
        search_permissions: search_permissions(s, thing),
        query: s.filter.query,
        cursor: MessageThreadCollection.init_cursor
      )
      out[:records].any?
    end
  end

  def search_permissions(subscription, thing)
    result = { tenant: subscription.user.tenant }
    result[:tag_ids] = Pundit.policy_scope(subscription.user, Tag).pluck(:id)
    result[:only_id] = thing.id # focus search to only one id
    result
  end

  def update_snapshot(thread)
    # we use search engine as before/after snapshot storage
    Searchable::ReindexMessageThreadJob.perform_now(thread.id)
  end
end
