class FillMissingRecipientsOrSenders < ActiveRecord::Migration[7.1]
  def up
    Govbox::Message.find_each do |govbox_message|
      message = ::Message.where(uuid: govbox_message.message_id).joins(:thread).where(thread: { box_id: govbox_message.box.id }).take

      raw_message = govbox_message.payload

      sender_name = raw_message["sender_name"]
      recipient_name = raw_message["recipient_name"]

      if govbox_message.payload["sender_uri"] == govbox_message.folder.box.uri
        sender_name ||= govbox_message.folder.box.name
      elsif govbox_message.payload["recipient_uri"] == govbox_message.folder.box.uri
        recipient_name ||= govbox_message.folder.box.name
      end

      message&.update!(
        recipient_name: recipient_name,
        sender_name: sender_name
      )
    end
  end
end
