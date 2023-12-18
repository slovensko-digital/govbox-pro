json.tags @thread.tags.pluck(:name)
json.messages(@thread.messages.map { |message| api_message_url(message) })
