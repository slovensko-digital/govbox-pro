class FixMessageRelations < ActiveRecord::Migration[7.0]
  def up
    MessageRelation.destroy_all

    Message.find_each do |message|
      main_message = Message.where(uuid: message.metadata["reference_id"]).joins(thread: :folder).where(folders: { box_id: message.thread.box.id }).take

      main_message.message_relations.find_or_create_by!(
        related_message: message,
      ) if main_message
    end
  end
end
