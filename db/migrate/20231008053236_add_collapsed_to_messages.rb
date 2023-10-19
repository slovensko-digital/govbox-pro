class AddCollapsedToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :collapsed, :boolean

    Message.order(:delivered_at).find_each do |message|
      next if message.is_a?(MessageDraft)

      govbox_message = Govbox::Message.find_by(message_id: message.uuid)

      message.update(collapsed: govbox_message.collapsed?)

      delivery_notification_govbox_message = Govbox::Message.where("payload -> 'delivery_notification' -> 'consignment' ->> 'message_id' = ?", govbox_message.message_id).joins(folder: :box).where(folders: { boxes: { id: govbox_message.box.id } }).take

      if delivery_notification_govbox_message
        delivery_notification_message = ::Message.find_by(uuid: delivery_notification_govbox_message.message_id)
        delivery_notification_message.update(collapsed: true)
      end
    end

    # change_column :messages, :collapsed, :boolean, null: false, default: false
  end
end
