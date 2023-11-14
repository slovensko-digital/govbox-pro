class AddDeliveryNotificationTagToThreads < ActiveRecord::Migration[7.0]
  def up
    MessageThread.find_each do |message_thread|
      to_be_authorized_messages = message_thread.messages.select(&:can_be_authorized?)

      if to_be_authorized_messages.any?
        delivery_notification_tag = Tag.find_or_create_by!(
          system_name: "DeliveryNotifications",
          tenant: message_thread.box.tenant,
        ) do |tag|
          tag.name = "Na prevzatie"
        end

        to_be_authorized_messages.each { |message| message.tags << delivery_notification_tag }

        message_thread.tags << delivery_notification_tag unless message_thread.tags.include?(delivery_notification_tag)
      end
    end
  end
end
