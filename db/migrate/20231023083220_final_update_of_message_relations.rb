class FinalUpdateOfMessageRelations < ActiveRecord::Migration[7.0]
  def up
    upvs_client = UpvsEnvironment.upvs_client

    Govbox::Message.find_each do |govbox_message|
      edesk_api = upvs_client.api(govbox_message.box).edesk
      _, raw_message = edesk_api.fetch_message(govbox_message.edesk_message_id)

      govbox_message.update(payload: raw_message)

      message = Message.where(uuid: govbox_message.message_id).joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take
      message.metadata["reference_id"] = govbox_message.payload["reference_id"]
      message.save
    end

    Message.order(:delivered_at).find_each do |message|
      if message.is_a?(MessageDraft)
        message.update(collapsed: false)
        next
      end

      govbox_message = Govbox::Message.where(message_id: message.uuid).joins(folder: :box).where(folders: { boxes: { id: message.thread.box.id } }).take

      message.update(collapsed: govbox_message.collapsed?)

      delivery_notification_govbox_message = Govbox::Message.where("payload -> 'delivery_notification' -> 'consignment' ->> 'message_id' = ?", govbox_message.message_id).joins(folder: :box).where(folders: { boxes: { id: govbox_message.box.id } }).take

      if delivery_notification_govbox_message
        delivery_notification_message = ::Message.where(uuid: delivery_notification_govbox_message.message_id).joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take

        if delivery_notification_message
          delivery_notification_message.collapsed = true
          delivery_notification_message.metadata["authorized"] = true
          delivery_notification_message.save!
        end
      end
    end

    MessageRelation.destroy_all

    Message.find_each do |message|
      main_message = Message.where(uuid: message.metadata["reference_id"]).joins(thread: :folder).where(folders: { box_id: message.thread.box.id }).take

      main_message.message_relations.find_or_create_by!(
        related_message: message,
      ) if main_message
    end
  end
end
