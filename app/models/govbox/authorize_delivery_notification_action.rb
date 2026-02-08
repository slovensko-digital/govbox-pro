class Govbox::AuthorizeDeliveryNotificationAction
  def self.run(message, jobs_batch: nil)
    can_be_authorized = message.can_be_authorized?

    if can_be_authorized
      message.metadata["authorized"] = "in_progress"
      message.save!

      Govbox::Message.remove_delivery_notification_tag(message)

      if jobs_batch
        jobs_batch.add { Govbox::AuthorizeDeliveryNotificationJob.set(job_context: :asap).perform_later(message) }
      else
        Govbox::AuthorizeDeliveryNotificationJob.set(job_context: :asap).perform_later(message)
      end

      EventBus.publish(:message_delivery_authorized, message)
    end

    can_be_authorized
  end
end
