class CreateNestedMessageObjectsFromExistingMessageObjects < ActiveRecord::Migration[7.0]
  def change
    MessageObject.find_each do |message_object|
      next unless message_object.asice?

      nested_message_objects = SignedAttachment::Asice.extract_documents_from_content(message_object.content)

      nested_message_objects.each do |nested_message_object|
        message_object.nested_message_objects.find_or_create_by!(
          name: nested_message_object.name,
          mimetype: nested_message_object.mimetype,
          content: nested_message_object.content
        )
      end
    end
  end
end
