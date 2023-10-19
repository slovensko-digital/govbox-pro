class FillMessageRelations < ActiveRecord::Migration[7.0]
  def up
    Message.find_each do |message|
      main_message = Message.find_by(uuid: message.metadata["reference_id"])

      main_message&.message_relations&.find_or_create_by!(
        related_message: message,
      )
    end
  end
end
