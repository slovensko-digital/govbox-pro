class Govbox::AuthorizeDeliveryNotificationAction
  JOB_PRIORITY = -1000

  def self.run(message)
    can_be_authorized = message.can_be_authorized?

    if can_be_authorized
      message.metadata["authorized"] = "in_progress"
      message.save!

      Govbox::Message.remove_delivery_notification_tag(message)
      Govbox::AuthorizeDeliveryNotificationJob.set(priority: JOB_PRIORITY).perform_later(message)

      EventBus.publish(:message_delivery_authorized, message)
    end

    can_be_authorized
  end
end
