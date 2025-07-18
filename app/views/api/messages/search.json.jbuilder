json.id @message.id
json.thread_id @message.message_thread_id
json.uuid @message.uuid
json.title @message.title
json.sender_name @message.sender_name
json.recipient_name @message.recipient_name
json.delivered_at @message.delivered_at
json.status @message.metadata.dig('status') if @message.metadata.dig('status').present?
json.metadata @message.metadata
json.tags @message.tags.pluck(:name)

json.objects @message.objects do |object|
  json.id object.id
  json.name object.name
  json.mimetype object.mimetype
  json.object_type object.object_type
  json.updated_at object.updated_at
  json.is_signed object.is_signed
  json.data Base64.encode64(object.message_object_datum.blob)
end
