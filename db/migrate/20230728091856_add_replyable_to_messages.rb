class AddReplyableToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :replyable, :boolean

    Message.find_each do |message|
      govbox_message = Govbox::Message.find_by(message_id: message.uuid)
      message.update(
        replyable: govbox_message.replyable?
      )
    end

    change_column :messages, :replyable, :boolean, null: false, default: true
  end
end
