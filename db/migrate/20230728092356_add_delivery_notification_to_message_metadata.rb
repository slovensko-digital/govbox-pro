class AddDeliveryNotificationToMessageMetadata < ActiveRecord::Migration[7.0]
  def change
    Message.find_each do |message|
      govbox_message = Govbox::Message.find_by(message_id: message.uuid)
      message.metadata["delivery_notification"] = govbox_message.payload["delivery_notification"]
      message.save!
    end
  end
end
