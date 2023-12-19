class NotifyFilterSubscriptionJob < ApplicationJob
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

    key: -> { "NotifyFilterSubscriptionJob-#{arguments.second}" }
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
