class NotifyFilterSubscriptionJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  # The ids are used instead of the records themselves, because the label is
  # resolved again when the job is performed. The label includes the subscription,
  # so that the limits do not drop the jobs of other subscriptions to the thread.
  good_job_concurrency_rule(
    label: -> { "NotifyFilterSubscriptionJob-#{arguments.first.try(:id)}-#{arguments.second.try(:id)}" },
    apply_label: true,
    total_limit: 2,
    perform_limit: 1
  )

  def perform(subscription, thread, matched_before)
    Notification.transaction do
      run_started_at = Time.current

      subscription.event_types.each do |type|
        type.create_notifications!(subscription, thread, matched_before)
      end

      subscription.update!(last_notify_run_at: run_started_at)
    end
  end
end
