class Govbox::AuthorizeDeliveryNotificationsAction
  def self.run(message_threads)
    jobs_batch = GoodJob::Batch.new

    messages = message_threads.map(&:messages).flatten

    results = messages.map do |message|
      is_authorized = ::Govbox::AuthorizeDeliveryNotificationAction.run(message, perform: false)

      jobs_batch.add { authorize_job.perform_later(message) } if is_authorized

      is_authorized
    end

    jobs_batch.enqueue(on_finish: ::Govbox::AuthorizeDeliveryNotificationsFinishedJob, user: Current.user)

    results.select { |value| value }.present?
  end

  def self.authorize_job
    Govbox::AuthorizeDeliveryNotificationJob.set(job_context: :asap)
  end
end
