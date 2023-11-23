class AddUniqueIndexOnEdeskMessageIdFolderIdToGovboxMessages < ActiveRecord::Migration[7.0]
  def change
    Govbox::Message.find_each do |govbox_message|
      govbox_message.destroy if Govbox::Message.where(message_id: govbox_message.message_id).where(folder_id: govbox_message.folder_id).count > 1
    end

    ::Message.find_each do |message|
      message.destroy if ::Message.where(uuid: message.uuid).where(message_thread_id: message.message_thread_id).count > 1
    end

    add_index :govbox_messages, [:edesk_message_id, :folder_id], unique: true
  end
end

