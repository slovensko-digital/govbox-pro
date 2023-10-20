class ChangeMessagesCollapsedAttribute < ActiveRecord::Migration[7.0]
  def change
    Message.order(:delivered_at).find_each do |message|
      if message.is_a?(MessageDraft)
        message.update(collapsed: false)
        next
      end

      govbox_message = Govbox::Message.where(message_id: message.uuid)
                                      .joins(folder: :box).where(folders: { boxes: { id: message.thread.box.id } }).take

      message.update(collapsed: govbox_message.collapsed?)

      delivery_notification_govbox_message = Govbox::Message.where("payload -> 'delivery_notification' -> 'consignment' ->> 'message_id' = ?", govbox_message.message_id)
                                                            .joins(folder: :box).where(folders: { boxes: { id: govbox_message.box.id } }).take

      if delivery_notification_govbox_message
        delivery_notification_message = ::Message.where(uuid: delivery_notification_govbox_message.message_id)
                                                 .joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take
        delivery_notification_message.update(collapsed: true)
      end
    end

    change_column :messages, :collapsed, :boolean, null: false, default: false
  end
end
