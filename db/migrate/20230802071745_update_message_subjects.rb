class UpdateMessageSubjects < ActiveRecord::Migration[7.0]
  def up
    Message.find_each do |message|
      govbox_message = Govbox::Message.find_by(message_id: message.uuid)
      raw_message = govbox_message.payload

      folder = Folder.find_or_create_by!(
        name: "Inbox",
        box: govbox_message.box
      )

      message_title = if raw_message["general_agenda"]
        [raw_message["subject"], raw_message["general_agenda"]["subject"]].join(' - ')
      else
        raw_message["subject"]
      end

      message.update(title: message_title)

      message_thread = MessageThread.joins(:merge_identifiers).where("message_thread_merge_identifiers.uuid = ?", govbox_message.correlation_id).joins(folder: :box).where(folders: {boxes: {id: folder.box.id}}).take

      if message_thread.delivered_at == message.delivered_at
        message_thread.update(
          title: message_title
        )
      end
    end
  end
end
