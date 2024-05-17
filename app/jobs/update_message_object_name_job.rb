class UpdateMessageObjectNameJob < ApplicationJob
  def perform(message_object)
    message_object.update(
      name: message_object.name + Utils.file_extension_by_mime_type(message_object.mimetype).to_s
    ) unless message_object.name.include?(Utils.file_extension_by_mime_type(message_object.mimetype).to_s)
  end
end
