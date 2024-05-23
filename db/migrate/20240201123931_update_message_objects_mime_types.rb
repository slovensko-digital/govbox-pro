class UpdateMessageObjectsMimeTypes < ActiveRecord::Migration[7.1]
  def change
    MessageObject.find_each { |message_object| message_object.update!(mimetype: Utils.file_mimetype_by_name(entry_name: message_object.name)) }
    NestedMessageObject.find_each { |message_object| message_object.update!(mimetype: Utils.file_mimetype_by_name(entry_name: message_object.name)) }
  end
end
