class UpdateMessageMetadata < ActiveRecord::Migration[7.0]
  def change
    Govbox::Message.find_each do |govbox_message|
      edesk_api = UpvsEnvironment.upvs_api(govbox_message.box).edesk
      response_status, raw_message = edesk_api.fetch_message(govbox_message.edesk_message_id)

      raise "Unable to fetch message" if response_status != 200

      govbox_message.update(payload: raw_message)

      message = ::Message.where(uuid: govbox_message.message_id).joins(thread: :folder).where(folders: { box_id: govbox_message.box.id }).take

      if message
        message.metadata["reference_id"] = govbox_message.payload["reference_id"]
        message.save
      end
    end
  end
end
