json.file_name @message_object.name
json.mime_type @message_object.mimetype
json.object_type @message_object.object_type
json.content Base64.strict_encode64(@message_object.content)
json.is_form @message_object.form?
json.fs_form_id @message_object.message.form&.identifier if @message_object.message.is_a? Fs::MessageDraft
