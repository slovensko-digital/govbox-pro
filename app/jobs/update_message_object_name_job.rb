class UpdateMessageObjectNameJob < ApplicationJob
  def perform(message_object)
    message_object.update(
      name: message_object.name + Utils.file_extension_by_mimetype(message_object.mimetype).to_s
    ) if Utils.file_name_without_extension?(message_object)
  end
end
