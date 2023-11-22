class Govbox::AuthorizeDeliveryNotificationAction
  def self.run(message)
    message.transaction do
      can_be_authorized = message.can_be_authorized?

      if can_be_authorized
        message.metadata["authorized"] = "in_progress"
        message.save!

        Govbox::Message.remove_delivery_notification_tag(message)
        Searchable::ReindexMessageThreadJob.new.perform(message.thread)
        Govbox::AuthorizeDeliveryNotificationJob.perform_later(message)
      end

      can_be_authorized
    end
  end
end
