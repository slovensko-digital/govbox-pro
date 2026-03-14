json.array! @api_connections do |api_connection|
  json.id api_connection.id
  json.custom_name api_connection.custom_name
  json.created_at api_connection.created_at
  json.updated_at api_connection.updated_at
end
