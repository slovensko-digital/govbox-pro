class AddUpvsFormDataToMessageMetadata < ActiveRecord::Migration[7.1]
  def change
    Message.where(type: [nil, 'Message']).find_each do |message|
      govbox_message = Govbox::Message.where(message_id: message.uuid)
                   .joins(folder: :box).where(folders: { boxes: { id: message.thread.box.id } }).take
      
      message.metadata['posp_id'] = govbox_message.payload['posp_id']
      message.metadata['posp_version'] = govbox_message.payload['posp_version']
      message.metadata['message_type'] = govbox_message.payload['message_type']
      message.save
    end
  end
end
