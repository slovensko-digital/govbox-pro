class UpdateReplyableAttributesOnMessages < ActiveRecord::Migration[7.0]
  def change
    Message.find_each do |message|
      govbox_message = Govbox::Message.find_by(message_id: message.uuid)
      message.update(replyable: govbox_message.replyable?)
    end
  end
end
