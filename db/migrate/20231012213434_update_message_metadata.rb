class UpdateMessageMetadata < ActiveRecord::Migration[7.0]
  def change
    upvs_client = UpvsEnvironment.upvs_client

    Govbox::Message.find_each do |govbox_message|
      edesk_api = upvs_client.api(govbox_message.box).edesk
      _, raw_message = edesk_api.fetch_message(govbox_message.edesk_message_id)

      govbox_message.update(payload: raw_message)

      message = Message.find_by(uuid: govbox_message.message_id)
      message.metadata["reference_id"] = govbox_message.payload["reference_id"]
      message.save
    end
  end
end
