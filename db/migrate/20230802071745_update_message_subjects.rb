class UpdateMessageSubjects < ActiveRecord::Migration[7.0]
  def up
    upvs_client = UpvsEnvironment.upvs_client

    Message.find_each do |message|
      govbox_message = Govbox::Message.find_by(message_id: message.uuid)

      edesk_api = upvs_client.api(govbox_message.folder.box).edesk
      _, raw_message = edesk_api.fetch_message(govbox_message.edesk_message_id)

      govbox_message.update(
        payload: raw_message
      )

      folder = Folder.find_or_create_by!(
        name: "Inbox",
        box: govbox_message.box
      )

      message_title = [raw_message["subject"], raw_message.dig("general_agenda", "subject")].compact.join(' - ')

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
