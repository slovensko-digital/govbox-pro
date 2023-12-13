json.id @message.id
json.uuid @message.uuid
json.title @message.title
json.sender_name @message.sender_name
json.recipient_name @message.recipient_name
json.delivered_at @message.delivered_at
json.metadata @message.metadata

json.objects @message.objects do |object|
  json.name object.name
  json.mimetype object.mimetype
  json.object_type object.object_type
  json.updated_at object.updated_at
  json.is_signed object.is_signed
  json.data Base64.encode64(object.message_object_datum.blob)
end
