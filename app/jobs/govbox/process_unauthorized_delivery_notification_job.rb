class Govbox::ProcessUnauthorizedDeliveryNotificationJob < ApplicationJob
  def perform(govbox_message)
    message = ::Message.where(uuid: govbox_message.message_id)
                       .joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take
    
    return if message.metadata["authorized"]

    end_of_delivery_period = Time.parse(govbox_message.delivery_notification['delivery_period_end_at'])
    if end_of_delivery_period > Time.now
      Govbox::ProcessUnauthorizedDeliveryNotificationJob.set(wait_until: end_of_delivery_period).perform_later(govbox_message)
      return
    end

    message.update(collapsed: true)

    delivery_notification_tag = Tag.find_by!(
      system_name: Govbox::Message::DELIVERY_NOTIFICATION_TAG,
      tenant: message.thread.box.tenant,
    )

    message.tags.delete(delivery_notification_tag) if message.tags.include?(delivery_notification_tag)
    unless message.thread.messages.any?(&:can_be_authorized?)
      message.thread.tags.delete(delivery_notification_tag)
    end
  end
end
