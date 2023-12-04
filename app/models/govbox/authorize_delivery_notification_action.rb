class Govbox::AuthorizeDeliveryNotificationAction
  def self.run(message)
    can_be_authorized = message.can_be_authorized?

    if can_be_authorized
      message.metadata["authorized"] = "in_progress"
      message.save!

      Govbox::Message.remove_delivery_notification_tag(message)
      Govbox::AuthorizeDeliveryNotificationJob.perform_now(message)

      EventBus.publish(:message_delivery_authorized, message)
    end

    can_be_authorized
  end
end
