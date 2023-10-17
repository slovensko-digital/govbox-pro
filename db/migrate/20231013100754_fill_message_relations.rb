class FillMessageRelations < ActiveRecord::Migration[7.0]
  def up
    Message.find_each do |message|
      govbox_message = Govbox::Message.find_by(message_id: message.uuid)
      related_message_type = govbox_message.related_message_type

      if related_message_type
        main_message = Message.find_by(uuid: message.metadata["reference_id"])

        main_message.message_relations.find_or_create_by(
          related_message: message,
          relation_type: related_message_type
        ) if main_message
      end
    end
  end
end
