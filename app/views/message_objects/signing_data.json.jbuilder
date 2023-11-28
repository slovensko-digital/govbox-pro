json.file_name @message_object.name
json.mime_type @message_object.mimetype
json.object_type @message_object.object_type
json.content Base64.strict_encode64(@message_object.content)
